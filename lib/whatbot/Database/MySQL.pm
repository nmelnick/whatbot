###########################################################################
# whatbot/Database/MySQL.pm
###########################################################################
# MySQL Connection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Database::MySQL;
use Moose;
extends 'whatbot::Database::DBI';

before 'connect' => sub {
	my ( $self ) = @_;
	
	my $config = $self->config->database;
	die 'MySQL requires a database name.' unless ( $config->{'database'} );
	
	my @params;
	push( @params, 'database=' . $config->{'database'} );
	push( @params, 'host=' . $config->{'host'} ) if ( $config->{'host'} );
	push( @params, 'port=' . $config->{'host'} ) if ( $config->{'port'} );
	
	$self->connect_array([
		'DBI:mysql:' . join( ';', @params ),
		( $config->{'username'} or '' ),
		( $config->{'password'} or '' )
	]);
};

sub integer {
    my ( $self, $size ) = @_;
    
    return 'int(' . $size . ')';
}

1;