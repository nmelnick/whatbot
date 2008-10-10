###########################################################################
# whatbot/Command/KarmaHistory.pm
###########################################################################
# 
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::KarmaHistory;
use Moose;
extends 'whatbot::Command';

sub register {
	my ($self) = @_;
	
	$self->command_priority("Extension");
	$self->listen_for(qr/^[\. ]*?who (hates|likes|loves|doesn't like|plussed|minused) (.*)/i);
	$self->require_direct(0);
}

sub parse_message {
	my ($self, $messageRef) = @_;
	
	if ($messageRef->content =~ $self->listen_for) {
		my $what = lc($1);
		my $subject = lc($2);
		$subject =~ s/[\.\?\! ]+$//;	# Remove punctuation
		$subject =~ s/^(the|a|an) //;	# Remove articles, if they exist
		
		my $op = "1";
		if ($what and ($what eq 'hates' or $what eq 'minused' or $what eq 'doesn\'t like')) {
			$op = "-1";
		}
		my @people = @{$self->store->retrieve("karma", ["DISTINCT user"], { subject => $subject, amount => $op })};
		if (scalar(@people) == 1) {
			if ($people[0]->{user} eq $messageRef->from) {
				return $messageRef->from . ": It was YOU!";
			} else {
				return $messageRef->from . ": It was " . $people[0]->{user} . ".";
			}
		} elsif (scalar(@people) > 10) {
			return $messageRef->from . ": More than 10 people, so seemlingly everyone.";
		} elsif (scalar(@people) > 0) {
			my $peopleText;
			foreach my $person (@people) {
				$peopleText .= ", " if ($peopleText);
				$peopleText .= $person->{user};
			}
			return $messageRef->from . ": " . $peopleText;
		} else {
			return $messageRef->from . ": Nobody!";
		}
	}
	
	return undef;
}

1;
