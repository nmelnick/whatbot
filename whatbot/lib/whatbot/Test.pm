use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::Test {
	use whatbot;
	use whatbot::Log;
	use whatbot::Component::Base;
	use whatbot::Config;
	use whatbot::Database::SQLite;

	has config_hash => ( is => 'rw', isa => 'HashRef' );

	method get_default_config() {
		return whatbot::Config->new(
			'config_hash' => ( $self->config_hash or {
				 'io' => [],
				 'database' => {
					 'handler' => 'SQLite',
					 'database' => '/tmp/whatbott.db'
				}
			} )
		);
	}

	method get_base_component() {
		# Build base component
		my $base_component = whatbot::Component::Base->new(
			'log'		=> whatbot::Log->new(),
			'config'    => $self->get_default_config()
		);
		$base_component->parent( whatbot->new({ 'base_component' => $base_component }) );
		my $database = whatbot::Database::SQLite->new(
		    'base_component' => $base_component
		);
		$database->connect();
		$base_component->database($database);

		return $base_component;
	}
}