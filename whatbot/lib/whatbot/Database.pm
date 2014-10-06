###########################################################################
# Database.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Database - Base class for data stores.

=cut

class whatbot::Database extends whatbot::Component {
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
