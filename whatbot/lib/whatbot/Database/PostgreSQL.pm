###########################################################################
# PostgreSQL.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Database::PostgreSQL - Connect whatbot to a PostgreSQL database.

=cut

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
			( $config->{'password'} or '' ),
			{
				'pg_enable_utf8' => 1,
			}
		]);
	};

	method last_insert_id( $table_name ) {
		return $self->handle->last_insert_id( undef, undef, $table_name, undef );
	}

	method serial ( $null? ) {
		return 'serial';
	}

}

1;

=pod

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
