###########################################################################
# whatbot/Connection/SQLite.pm
###########################################################################
# SQLite Connection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Connection::SQLite;
use Moose;
extends 'whatbot::Connection::DBI';

before 'connect' => sub {
	my ( $self ) = @_;
	
	die 'SQLite requires a database name.' unless ( $self->config->connection->{'database'} );
	
	$self->connect_array([
		'DBI:SQLite:dbname=' . $self->config->connection->{'database'},
		'',
		''
	]);
};

sub last_insert_id {
    my ($self) = @_;
    
    return $self->handle->func('last_insert_rowid');
}

sub timestamp {
    my ( $self ) = @_;
    
    return 'integer';
}

sub now {
    return time;
}

1;