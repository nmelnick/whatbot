###########################################################################
# DBI.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

Whatbot::Database::DBI - Basic functionality for DBI-based databases.

=cut

class Whatbot::Database::DBI extends Whatbot::Database {
	use DBI;

	has 'connect_array' => ( is => 'rw', isa => 'ArrayRef' );
	has 'tables'        => ( is => 'rw', isa => 'HashRef' );
	has 'postfix'       => ( is => 'rw', isa => 'Bool', default => 0 );

	method connect() {
		die "ERROR: No connect string offered by connection module" if ( !$self->connect_array );
		my $dbh = DBI->connect( @{$self->connect_array} ) or die $DBI::errstr;
		$self->handle($dbh);
		$self->get_tables();
	}

	method get_tables() {
		my %tables;
		my $sth = $self->handle->table_info();
		while ( my $rec = $sth->fetchrow_hashref() ) {
			$tables{ $rec->{'TABLE_NAME'} } = 1;
		}
		$sth->finish();
		
		return $self->tables(\%tables);
	}

	method last_insert_id( $table_name ) {
		$self->log->write( 'last_insert_id is unsupported by ' . ref($self) );
		return 0;
	}

	method char ( Int $size ) {
		return 'char(' . $size . ')';
	}

	method integer ( $null? ) {
		return 'integer';
	}

	method serial ( $null? ) {
		$self->postfix(1);
		return integer();
	}

	method double ( $null? ) {
		return 'double';
	}

	method varchar ( Int $size ) {
		return 'varchar(' . $size . ')';
	}

	method timestamp( $null? ) {
		return 'timestamp';
	}

	method text( $null? ) {
		return 'text';
	}

	method now() {
		return \'now()';
	}

	method random() {
		return 'random()';
	}

	method serial_postfix() {
		return '';
	}

}

1;

=pod

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
