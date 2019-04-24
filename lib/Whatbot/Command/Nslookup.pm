###########################################################################
# Whatbot/Command/Nslookup.pm
###########################################################################
# Utilizes system host command to get IP for hostname
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Nslookup;
use Moose;
use Whatbot::Command;
BEGIN { extends 'Whatbot::Command' }
use namespace::autoclean;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority("Extension");
	$self->require_direct(0);
}

sub parse_message : CommandRegEx('(.+)') {
	my ( $self, $message, $captures ) = @_;
	
	if ( $captures->[0] ) {
		my $host = $captures->[0];
		my $nslookup = `host $host`;
		if ($nslookup =~ /has address ([\d\.]+)/) {
			return $host . ' is at ' . $1;
		} elsif ($nslookup =~ /not found/) {
			return "I can't find " . $host;
		}
	}
	return;
}

__PACKAGE__->meta->make_immutable;

1;