###########################################################################
# whatbot/Database/SQLite.pm
###########################################################################
# SQLite Connection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::Database::SQLite extends whatbot::Database::DBI {

	before connect() {
		die 'SQLite requires a database name.' unless ( $self->config->database->{'database'} );
		
		$self->connect_array([
			'DBI:SQLite:dbname=' . $self->config->database->{'database'},
			'',
			''
		]);
	}

	method last_insert_id() {
	    return $self->handle->func('last_insert_rowid');
	}

	method timestamp() {
	    return 'integer';
	}

	method now() {
	    return $self->handle->quote(time);
	}

}

1;