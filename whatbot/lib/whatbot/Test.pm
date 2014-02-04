###########################################################################
# Test.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Test -- Unit test helpers for whatbot.

=head1 DESCRIPTION

This object provides helper methods for unit testing whatbot commands.

=head1 METHODS

=over 4

=cut

class whatbot::Test {
	use whatbot;
	use whatbot::Log;
	use whatbot::Config;
	use whatbot::Database::SQLite;
	use whatbot::State;

	has config_hash => ( is => 'rw', isa => 'HashRef' );

=item get_default_config()

Provide a default whatbot::Config instance with an empty test database already
configured. This is used by initialize_state().

=cut

	method get_default_config() {
		my $db = '/tmp/.whatbot.test.db';
		if ( -e $db ) {
			unlink($db);
		}
		return whatbot::Config->new(
			'config_hash' => ( $self->config_hash or {
				 'io' => [],
				 'database' => {
					 'handler'  => 'SQLite',
					 'database' => $db,
				}
			} )
		);
	}

=item initialize_state()

Initializes a default whatbot::State for initializing new Commands or other
Components. This utilizes the test database in get_default_config() and logs to
the screen.

=cut

	method initialize_state() {
		whatbot::State->initialize({
			'log'    => whatbot::Log->new(),
			'config' => $self->get_default_config()
		});
		my $state = whatbot::State->instance;
		$state->log->log_enabled(0);
		$state->parent( whatbot->new() );
		my $database = whatbot::Database::SQLite->new();
		$database->connect();
		$state->database($database);
		$state->log->log_enabled(1);

		return $state;
	}

=item initialize_models()

Loads and initializes all available models/databases. Must be used before
testing a command that utilizes database calls.

=cut

	method initialize_models() {
		my $state = whatbot::State->instance;
		my $whatbot = $state->parent;
		$state->log->log_enabled(0);
		$whatbot->_initialize_models();
		$state->log->log_enabled(1);
		return;
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
