###########################################################################
# whatbot/Command/Excuse.pm
###########################################################################
# Utilizes an excuse server to deliver excuses on request
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Excuse;
use Moose;
extends 'whatbot::Command';
use Net::Telnet;

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Extension");
	$self->listenFor(qr/^excuse/i);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	my $excuseServer = Net::Telnet->new(
		Host 	=> "bob.bob.bofh.org",
		Port 	=> "666",
		Errmode => "return"
	);
	if (defined $excuseServer) {
		$excuseServer->waitfor("/Your excuse is: /");
		my $excuse = $excuseServer->get;
		foreach (split(/\n/, $excuse)) {
			$excuse = $_ if (/Your excuse is/);
		}
		chomp($excuse);
		return $messageRef->from . ": " . $excuse;
	} else {
		return "The excuse server is down.";
	}
}

1;