###########################################################################
# whatbot/Command/FactoidListener.pm
###########################################################################
# Listens for factoids said aloud and spews a response if it hears one.
# Separated to run after other extensions
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::FactoidListener;
use Moose;
BEGIN { extends 'whatbot::Command'; }

use whatbot::Command::Factoid;
use namespace::autoclean;

has 'factoid' => ( is => 'ro', isa => 'whatbot::Command::Factoid' );

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Last');
	$self->require_direct(0);
	$self->{'factoid'} = whatbot::Command::Factoid->new();
}

sub listener : GlobalRegEx('(.+)') {
	my ( $self, $message, $captures ) = @_;
	
	return $self->factoid->retrieve( $captures->[0], $message );
}

__PACKAGE__->meta->make_immutable;

1;
