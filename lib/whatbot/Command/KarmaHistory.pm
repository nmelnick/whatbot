###########################################################################
# whatbot/Command/KarmaHistory.pm
###########################################################################
# Using the karma history, determine what someone likes or doesn't like
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::KarmaHistory;
use Moose;
BEGIN { extends 'whatbot::Command' }

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub superlative : GlobalRegEx('^[\. ]*?what(?: is|'s)(?: the)? (best|worst)') {
	my ( $self, $message, $captures ) = @_;

	my $best = lc($captures->[0]) eq 'best';
	my $limit = 10;

	my $sort = ($best ? "desc" : "asc");
	my $sth = $self->store->handle->prepare("select subject, total from (select subject, sum(amount) as total from karma group by subject) order by total $sort limit $limit");
	$sth->execute();

	my $out = "The " . ($best ? "best" : "worst") . " of everything is: ";

	my $row;
	while ($row = $sth->fetchrow_arrayref) {
		my ($subject, $total) = @$row;
		$out .= "$subject ($total) ";
        }
	return $out;
}

sub parse_message : GlobalRegEx('^[\. ]*?who (hates|likes|loves|doesn\'t like|plussed|minused) (.*)') {
	my ( $self, $message, $captures ) = @_;
	
	if ($captures) {
		my $what = lc( $captures->[0] );
		my $subject = lc( $captures->[1] );
		$subject =~ s/[\.\?\! ]+$//;	# Remove punctuation
		$subject =~ s/^(the|a|an) //;	# Remove articles, if they exist
		
		my $sort = "desc";
		my $op = "1";
		if ( $what and ( $what eq 'hates' or $what eq 'minused' or $what eq 'doesn\'t like' ) ) {
			$sort = "asc";
			$op = "-1";
		}

                my $sth = $self->store->handle->prepare("select user, total from (select user, sum(amount) as total from karma where subject = '$subject' and amount = $op group by user) order by total $sort");
		$sth->execute;

		my @people;
		my $row;
		while ($row = $sth->fetchrow_arrayref) {
			my ($user, $total) = @$row;

			push @people, { user => $user, total => $total };
		}
		
		if (scalar(@people) == 1) {
			my $num = abs($people[0]->{total});
			my $who = $people[0]->{user};

			my $howmuch = ($num == 1 ? "once" : $num == 2 ? "twice" : "$num times");

			if ($who eq $message->from) {
				return $message->from . ': It was YOU! ' . ucfirst($howmuch) . ".";
			} else {
				return $message->from . ': It was ' . $people[0]->{'user'} . ", $howmuch.";
			}
			
		} elsif (scalar(@people) > 10) {
			return $message->from . ': More than 10 people, so nearly everyone.';
			
		} elsif (scalar(@people) > 0) {
			my $peopleText = join ', ', map { $_->{user} . " (" . $_->{total} . ")" } @people;
			return $message->from . ': ' . $peopleText;
			
		} else {
			return $message->from . ': Nobody!';
		}
	}
	
	return undef;
}

1;
