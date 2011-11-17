###########################################################################
# whatbot/Database/DBI.pm
###########################################################################
# Base for any DBI connection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::Database::DBI extends whatbot::Database {
    use DBI;

    has 'connect_array' => ( is => 'rw', isa => 'ArrayRef' );
    has 'tables'        => ( is => 'rw', isa => 'HashRef' );

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

    method last_insert_id() {
        $self->log->write( 'last_insert_id is unsupported by ' . ref($self) );
        return 0;
    }

    method char ( Int $size ) {
        return 'char(' . $size . ')';
    }

    method integer ( $null? ) {
        return 'integer';
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

}

1;