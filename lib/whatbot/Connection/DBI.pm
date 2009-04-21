###########################################################################
# whatbot/Connection/DBI.pm
###########################################################################
# Base for any DBI connection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Connection::DBI;
use Moose;
extends 'whatbot::Connection';
use DBI;

has 'connect_array' => ( is => 'rw', isa => 'ArrayRef' );
has 'tables'        => ( is => 'rw', isa => 'HashRef' );

sub connect {
	my ( $self ) = @_;
	
	die "ERROR: No connect string offered by connection module" if ( !$self->connect_array );
	
	my $dbh = DBI->connect( @{$self->connect_array} ) or die $DBI::errstr;
	$self->handle($dbh);
	$self->get_tables();
}

sub get_tables {
    my ( $self ) = @_;
    
    my %tables;
    my $sth = $self->handle->table_info();
    while ( my $rec = $sth->fetchrow_hashref() ) {
        $tables{ $rec->{'TABLE_NAME'} } = 1;
    }
    $sth->finish();
    
    return $self->tables(\%tables);
}

sub last_insert_id {
    my ( $self ) = @_;
    
    $self->log->write( 'last_insert_id is unsupported by ' . ref($self) );
    return 0;
}

sub char {
    my ( $self, $size ) = @_;
    
    return 'char(' . $size . ')';
}

sub integer {
    my ( $self, $size ) = @_;
    
    return 'integer';
}

sub timestamp {
    return 'timestamp';
}

sub text {
    return 'text';
}

sub varchar {
    my ( $self, $size ) = @_;
    
    return 'varchar(' . $size . ')';
}

sub now {
    return \'now()';
}

1;