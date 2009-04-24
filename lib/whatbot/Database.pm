###########################################################################
# whatbot/Database.pm
###########################################################################
# Base class for whatbot Database
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Database;
use Moose;
extends 'whatbot::Component';

has 'handle' => ( is => 'rw', isa => 'Any' );

sub connect {
	my ( $self ) = @_;
	
	$self->log->error( ref($self) . ' does not know how to connect.' );
}

1;