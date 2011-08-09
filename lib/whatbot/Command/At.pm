###########################################################################
# whatbot/Command/PageRank.pm
###########################################################################
# Gathers the google pagerank for a given site
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

sub register {
	my ( $self ) = @_;
	
	$self->command_priority("Extension");
	$self->require_direct(1);
}

sub run_at {
	my ( $self, $medium, $from, $what ) = @_;

    $medium->event_message_public($from, $what);
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
    $self->timer->enqueue($time->epoch, \&run_at, $self, $medium, $message->from, $do_what);
    return "ok, I will do that.";
}

1;
