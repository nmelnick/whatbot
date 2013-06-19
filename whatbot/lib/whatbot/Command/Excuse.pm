###########################################################################
# whatbot/Command/Excuse.pm
###########################################################################
# Utilizes an excuse server to deliver excuses on request
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Excuse;
use Moose;
BEGIN { extends 'whatbot::Command' }

use Net::Telnet;
use namespace::autoclean;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub parse_message : CommandRegEx('') {
	my ( $self, $message ) = @_;
	
	my $excuseServer = Net::Telnet->new(
		Host 	=> 'bob.bob.bofh.org',
		Port 	=> '666',
		Errmode => 'return'
	);
	if (defined $excuseServer) {
		$excuseServer->waitfor('/Your excuse is: /');
		my $excuse = $excuseServer->get;
		foreach (split(/\n/, $excuse)) {
			$excuse = $_ if (/Your excuse is/);
		}
		chomp($excuse);
		return $message->from . ': ' . $excuse;
	} else {
		return 'The excuse server is down.';
	}
}

sub help {
    return 'Excuse uses an excuse server to deliver a random response to your inquiry. Even better, the inquiry is optional.';
}

__PACKAGE__->meta->make_immutable;

1;