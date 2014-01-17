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
	use whatbot::Component::Base;
	use whatbot::Config;
	use whatbot::Database::SQLite;

	has config_hash => ( is => 'rw', isa => 'HashRef' );

=item get_default_config()

Provide a default whatbot::Config instance with an empty test database already
configured. This is used by get_base_component().

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

=item get_base_component()

Provide a default whatbot::Component::Base instance for initializing new
Commands or other Components. This utilizes the test database in
get_default_config() and logs to the screen.

=cut

	method get_base_component() {
		# Build base component
		my $base_component = whatbot::Component::Base->new(
			'log'    => whatbot::Log->new(),
			'config' => $self->get_default_config()
		);
		$base_component->log->log_enabled(0);
		$base_component->parent( whatbot->new({ 'base_component' => $base_component }) );
		my $database = whatbot::Database::SQLite->new(
		    'base_component' => $base_component
		);
		$database->connect();
		$base_component->database($database);
		$base_component->log->log_enabled(1);

		return $base_component;
	}

=item initialize_models( $base_component )

Loads and initializes all available models/databases. Must be used before
testing a command that utilizes database calls.

=cut

	method initialize_models( $base_component ) {
		my $whatbot = $base_component->parent;
		$base_component->log->log_enabled(0);
		$whatbot->_initialize_models($base_component);
		$whatbot->_initialize_models($base_component);
		$base_component->log->log_enabled(1);
		return;
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
