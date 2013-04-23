###########################################################################
# whatbot/Database/PostgreSQL.pm
###########################################################################
# PostgreSQL Connection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::Database::PostgreSQL extends whatbot::Database::DBI {

	before connect() {
		my $config = $self->config->database;
		die 'PostgreSQL requires a database name.' unless ( $config->{'database'} );
		
		my @params;
		push( @params, 'dbname=' . $config->{'database'} );
		push( @params, 'host=' . $config->{'host'} ) if ( $config->{'host'} );
		push( @params, 'port=' . $config->{'host'} ) if ( $config->{'port'} );
		
		$self->connect_array([
			'DBI:Pg:' . join( ';', @params ),
			( $config->{'username'} or '' ),
			( $config->{'password'} or '' )
		]);
	};

}

1;