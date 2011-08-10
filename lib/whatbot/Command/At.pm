###########################################################################
# whatbot/Command/At.pm
###########################################################################
# Ridiculously unnecessary at/every scheduling.
#
# Pretends to be input received as normal, at the specified times.
# 
# How to use:
#  whatbot, at <a time in english>, <input>
#  whatbot, at list
#  whatbot, at delete <#>
#
#  whatbot, every <period in english>, <validity period>, 
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::At;
use Moose;
BEGIN { extends 'whatbot::Command' }

use DateTime;
use DateTime::Format::Natural;

has 'parser' => (
	is		=> 'ro',
	isa		=> 'DateTime::Format::Natural',
	default => sub { DateTime::Format::Natural->new(
		time_zone => "local",
	); }
);

my %at_list;
my %every_list;

my $next_at_id    = 1;
my $next_every_id = 1;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority("Extension");
	$self->require_direct(1);
}

sub run_at {
	my ( $self, $medium, $from, $what, $id ) = @_;

    $medium->event_message_public($from, $what);
    delete $at_list{$id};
}

sub run_every {
	my ( $self, $medium, $from, $what, $id, $end_validity, $periodspec ) = @_;

    $medium->event_message_public($from, $what);

	if ($end_validity->epoch <= time) {
		# all done.
		return;
	}

	my ($startperiod, $endperiod) = $self->parser->parse_datetime_duration("for " .$periodspec);

	if (!$self->parser->success || !defined($startperiod) || !defined($endperiod)) {
		delete $every_list{$id};
		return "error re-enqueuing 'every' #$id: '$what'. dropped.";
	}

	if ($end_validity->epoch <= $endperiod->epoch) {
		# all done.
		return;
	}

	my $queuespec = [$endperiod->epoch, \&run_every, $self, $medium, $from, $what, $id, $end_validity, $periodspec];
	$self->timer->enqueue(@$queuespec);
	$every_list{$id} = [$periodspec, $end_validity, $what, $from, $queuespec];
}

sub parse_every : GlobalRegEx('^every ([^,]+), ([^,]+), (.+)$') {
	my ( $self, $message, $captures ) = @_;
	
	my $periodspec = $captures->[0];
	my $validityspec = $captures->[1];
	my $do_what = $captures->[2];

	if ($periodspec =~ /^\w+$/) {
		# one word
		$periodspec = "1 $periodspec";
	}

	my ($startperiod, $endperiod) = $self->parser->parse_datetime_duration("for " .$periodspec);

	if (!$self->parser->success || !defined($startperiod) || !defined($endperiod)) {
		return "what. '$periodspec' isn't a period of time i understand (try 'n minutes', etc).";
	}

	$validityspec =~ s/^until /now to /;
	
	my ($startvalid, $endvalid) = $self->parser->parse_datetime_duration($validityspec);
	if (!$self->parser->success || !defined($startvalid) || !defined($endvalid)) {
		return "what. '$validityspec' isn't a validity period i understand (try 'until october 1st' or 'until 1pm' or 'may 2nd to 5th')";
	}

	if ($endvalid->epoch <= time) {
		my $now = DateTime->now(time_zone => "local");

		return "that validity ends in the past ($endvalid). right now it's $now for me.";
	}

	my $first_time = $startvalid + $endperiod->subtract_datetime($startperiod);

	if ($first_time->epoch <= time) {
		return "the first time that'll run will be in the past. ($first_time).";
	}

	my $medium = $message->origin;
	my $id = $next_every_id++;
	my $queuespec = [$first_time->epoch, \&run_every, $self, $medium, $message->from, $do_what, $id, $endvalid, $periodspec];

	$self->timer->enqueue(@$queuespec);
	$every_list{$id} = [$periodspec, $endvalid, $do_what, $message->from, $queuespec];

    return "ok, I will do that, starting at $first_time until $endvalid every $periodspec. (every #$id)";
}

sub parse_message : CommandRegEx('([^,]+), (.+)') {
	my ( $self, $message, $captures ) = @_;
	
	my $timespec = $captures->[0];
	my $do_what = $captures->[1];

	my $time = $self->parser->parse_datetime($timespec);

	if (!$self->parser->success) {
		return "wtf is '$timespec'";
	}

	if ($time->epoch <= time) {
		my $now = DateTime->now(time_zone => "local");

		return "that time ($time) is in the past. right now it's $now for me.";
	}

	$self->log->write("Creating -at- for time: $time");

	my $medium = $message->origin;
	my $id = $next_at_id++;

    my $queuespec = [$time->epoch, \&run_at, $self, $medium, $message->from, $do_what, $id];
    
    $self->timer->enqueue(@$queuespec);

    $at_list{$id} = [$time, $do_what, $message->from, $queuespec];

    return "ok, I will do that at $time. (at #$id)";
}

sub do_every_list : GlobalRegEx('^every list$') {
	my ( $self, $message, $captures ) = @_;

	my @out;
	foreach my $id (sort keys(%every_list)) {
		my ($periodspec, $endtime, $do_what, $who, $qargs) = @{$every_list{$id}};

		push @out, "$id. $do_what (every $periodspec until $endtime, from $who)";
	}

	if (!@out) {
		return "the every list is empty.";
	}

	return \@out;
}

sub do_at_list : GlobalRegEx('^at list$') {
	my ( $self, $message, $captures ) = @_;

	my @out;
	foreach my $id (sort keys(%at_list)) {
		my ($time, $do_what, $who, $qargs) = @{$at_list{$id}};

		push @out, "$id. $do_what (at $time, from $who)";
	}

	if (!@out) {
		return "the at list is empty.";
	}

	return \@out;
}

sub do_every_delete : GlobalRegEx('^(every|at) delete (\d+)$') {
	my ( $self, $message, $captures ) = @_;

	my $do_every = (lc($captures->[0]) eq 'every');
	my $id = $captures->[1];

	if ($do_every) {
		if (!exists($every_list{$id})) {
			return "there is no every #$id.";
		} else {
			my $removed = $self->timer->remove(@{$every_list{$id}->[4]});
			return "unable to remove?! :(" unless $removed;
			delete $every_list{$id};
			return "deleted every #$id.";
		}
	} else {
		if (!exists($at_list{$id})) {
			return "there is no at #$id.";
		} else {
			my $removed = $self->timer->remove(@{$at_list{$id}->[3]});
			return "unable to remove?! :(" unless $removed;
			delete $at_list{$id};
			return "deleted at #$id.";
		}
	}

	return "nothing happened, wtf broken code";
}

1;
