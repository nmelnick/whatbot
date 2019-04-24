###########################################################################
# Whatbot/Command/FactoidListener.pm
###########################################################################
# Listens for factoids said aloud and spews a response if it hears one.
# Separated to run after other extensions
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::FactoidListener;
use Moose;
use Whatbot::Command;
BEGIN { extends 'Whatbot::Command'; }

use Whatbot::Command::Factoid;
use namespace::autoclean;

has 'factoid' => ( is => 'ro', isa => 'Whatbot::Command::Factoid' );

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Last');
	$self->require_direct(0);
	$self->{'factoid'} = Whatbot::Command::Factoid->new();
}

sub listener : GlobalRegEx('(.+)') {
	my ( $self, $message, $captures ) = @_;
	
	return $self->factoid->retrieve( $captures->[0], $message );
}

__PACKAGE__->meta->make_immutable;

1;
