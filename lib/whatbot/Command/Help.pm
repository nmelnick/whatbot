###########################################################################
# whatbot/Command/Help.pm
###########################################################################
# DEFAULT: Grabs help for a given command
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Help;
use Moose;
extends 'whatbot::Command';

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Primary");
	$self->listenFor(qr/^help ?(.*)?/);
	$self->requireDirect(1);
}

sub parseMessage {
	my ($self, $messageRef) = @_;

	if ($messageRef->content =~ $self->listenFor) {
	    if ($1) {
	        if (defined $self->controller->CommandNames->{$1}) {
	            return $self->controller->CommandNames->{$1}->help();
	        } else {	            
    	        return
    	            'No such command: "' . $1 . '". Help is available for: ' .
    	            join(', ', keys %{$self->controller->CommandNames});
	        }
	    } else {
	        return
	            'Whatbot is a modular, extensible, buzzword-compliant chat bot ' .
	            'written in Perl and tears. Help is available for: ' .
	            join(', ', keys %{$self->controller->CommandNames});
	    }
	}
    return undef;
}

1;
