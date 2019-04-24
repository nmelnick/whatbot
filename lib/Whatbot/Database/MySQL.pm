###########################################################################
# MySQL.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Database::MySQL - Connect whatbot to a MySQL database.

=cut

class Whatbot::Database::MySQL extends Whatbot::Database::DBI {

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

=pod

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
