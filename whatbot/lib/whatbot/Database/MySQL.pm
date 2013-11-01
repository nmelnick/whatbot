###########################################################################
# whatbot/Database/MySQL.pm
###########################################################################
# MySQL Connection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::Database::MySQL extends whatbot::Database::DBI {

	before connect() {
		my $config = $self->config->database;
		die 'MySQL requires a database name.' unless ( $config->{'database'} );
		
		my @params;
		push( @params, 'database=' . $config->{'database'} );
		push( @params, 'host=' . $config->{'host'} ) if ( $config->{'host'} );
		push( @params, 'port=' . $config->{'host'} ) if ( $config->{'port'} );
		
		$self->connect_array([
			'DBI:mysql:' . join( ';', @params ),
			( $config->{'username'} or '' ),
			( $config->{'password'} or '' ),
			{
				'mysql_enable_utf8' => 1,
			}
		]);
	};

	method integer ( Int $size ) {
	    return 'int(' . $size . ')';
	}

    method random() {
        return 'rand()';
    }

}

1;