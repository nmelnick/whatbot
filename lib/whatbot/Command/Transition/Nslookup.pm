###########################################################################
# whatbot/Command/Nslookup.pm
###########################################################################
# Utilizes system host command to get IP for hostname
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Nslookup;
use Moose;
extends 'whatbot::Command';

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Extension");
	$self->listenFor(qr/^nslookup (.*?)$/i);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	if ($messageRef->content =~ $self->listenFor) {
		my $host = $1;
		my $nslookup = `host $host`;
		if ($nslookup =~ /has address ([\d\.]+)/) {
			return $host . " is at " . $1;
		} elsif ($nslookup =~ /not found/) {
			return "I can't find " . $host;
		}
	}
	return undef;
}

1;