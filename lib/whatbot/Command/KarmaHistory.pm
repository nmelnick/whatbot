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

sub parse_message : GlobalRegEx('^[\. ]*?who (hates|likes|loves|doesn\'t like|plussed|minused) (.*)') {
	my ( $self, $message, $captures ) = @_;
	
	if ($captures) {
		my $what = lc( $captures->[0] );
		my $subject = lc( $captures->[1] );
		$subject =~ s/[\.\?\! ]+$//;	# Remove punctuation
		$subject =~ s/^(the|a|an) //;	# Remove articles, if they exist
		
		my $op = '1';
		if ( $what and ( $what eq 'hates' or $what eq 'minused' or $what eq 'doesn\'t like' ) ) {
			$op = '-1';
		}
		my @people = @{$self->store->retrieve('karma', ['DISTINCT user'], { 'subject' => $subject, 'amount' => $op })};
		
		if (scalar(@people) == 1) {
			if ($people[0]->{'user'} eq $message->from) {
				return $message->from . ': It was YOU!';
			} else {
				return $message->from . ': It was ' . $people[0]->{'user'} . '.';
			}
			
		} elsif (scalar(@people) > 10) {
			return $message->from . ': More than 10 people, so nearly everyone.';
			
		} elsif (scalar(@people) > 0) {
			my $peopleText;
			foreach my $person (@people) {
				$peopleText .= ', ' if ($peopleText);
				$peopleText .= $person->{'user'};
			}
			return $message->from . ': ' . $peopleText;
			
		} else {
			return $message->from . ': Nobody!';
		}
	}
	
	return undef;
}

1;
