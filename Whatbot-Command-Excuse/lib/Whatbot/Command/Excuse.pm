###########################################################################
# Whatbot/Command/Excuse.pm
###########################################################################
# Utilizes an excuse server to deliver excuses on request
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Excuse;
use Moose;
BEGIN { extends 'Whatbot::Command' }

use Net::Telnet;
use namespace::autoclean;

our $VERSION = '0.1';

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub parse_message : CommandRegEx('') {
	my ( $self, $message ) = @_;
	
	my $excuseServer = Net::Telnet->new(
		Host 	=> ( $self->my_config->{'host'} or 'bob.bob.bofh.org' ),
		Port 	=> ( $self->my_config->{'port'} or '666' ),
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
    return 'Excuse uses an excuse server to deliver a random response to your '
         . 'inquiry. Even better, the inquiry is optional.';
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Whatbot::Command::Excuse - Provide excuses from an excuse server.

=head1 CONFIG (optional)

"excuse" : {
	"host" : "bob.bob.bofh.org",
	"port" : 666
}

=head1 DESCRIPTION

Whatbot::Command::Excuse will query an excuse server and return it to the
caller. Utilizes bob.bob.bofh.org:666 by default, but can be configured to use
another server.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
