###########################################################################
# whatbot/Command/Awareness.pm
###########################################################################
# This is basic, just responds to a name.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Awareness;
use Moose;
extends 'whatbot::Command';

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Primary");
	$self->listenFor("");
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	# Self-awareness
	my $me = $messageRef->me;
	return "what" if ($messageRef->content =~ /^$me[\?\!\.]?$/i);
	
	# Greeting
	my @greetings = (
		"hey",
		"sup",
		"what's up",
		"yo",
		"word",
		"hi"
	);
	if ($messageRef->isDirect and $messageRef->content =~ /^(hey|hi|hello|word|sup|morning|good morning)[\?\!\. ]*?$/) {
		return $greetings[rand @greetings] . ", " . $messageRef->from . ".";
	}

	return undef;
}

1;