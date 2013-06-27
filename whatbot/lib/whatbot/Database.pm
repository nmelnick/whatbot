###########################################################################
# whatbot/Database.pm
###########################################################################
# Base class for whatbot Database
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::Database extends whatbot::Component {
    has 'handle' => ( is => 'rw', isa => 'Any' );

    method connect {
    	$self->log->error( ref($self) . ' does not know how to connect.' );
    }
}

1;