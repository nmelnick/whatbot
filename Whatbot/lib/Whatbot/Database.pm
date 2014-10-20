###########################################################################
# Database.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

Whatbot::Database - Base class for data stores.

=cut

class Whatbot::Database extends Whatbot::Component {
	has 'handle' => ( is => 'rw', isa => 'Any' );

	method connect {
		$self->log->error( ref($self) . ' does not know how to connect.' );
	}
}

1;

=pod

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
