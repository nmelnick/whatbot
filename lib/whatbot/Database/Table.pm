###########################################################################
# whatbot/Database/Table.pm
###########################################################################
# Class wrapper for a database table
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Database::Table;
use Moose;
extends 'whatbot::Database';

use Data::Dumper;
use whatbot::Database::Table::Row;

has 'table_name'    => ( is => 'rw', isa => 'Str' );
has 'primary_key'   => ( is => 'rw', isa => 'Str' );
has 'columns'       => ( is => 'rw', isa => 'ArrayRef' );
has 'defaults'      => ( is => 'rw', isa => 'HashRef' );
# has 'column_info'   => ( is => 'rw', isa => 'HashRef' );

sub init_table {
    my ( $self, $table_data ) = @_;
    
    warn 'Missing name for table' unless ( $table_data->{'name'} );
    warn 'Missing column data for table' unless ( $table_data->{'columns'} );
    
    # Create table if it doesn't exist
    unless ( $self->database->tables->{ $table_data->{'name'} } ) {
        $self->log->write('Creating table "' . $table_data->{'name'} . '" for ' . caller() . '.' );
        $self->_make_table($table_data);
    }
    
    $self->table_name( $table_data->{'name'} );
    $self->primary_key( $table_data->{'primary_key'} ) if ( $table_data->{'primary_key'} );
    $self->columns([ keys %{ $table_data->{'columns'} } ]);
    $self->defaults( $table_data->{'defaults'} or {} );
    # $self->column_info( $table_data->{'columns'} );
}

sub create {
    my ( $self, $column_data ) = @_;
    
    my $params;
    foreach ( keys %{ $self->defaults } ) {
        $params->{$_} = $self->defaults->{$_};
    }
    foreach ( keys %$column_data ) {
        $params->{$_} = $column_data->{$_};
    }
    my $query = 'INSERT INTO ' . $self->table_name .
                ' (' . join( ', ', keys %$params ) . ') ' .
                'VALUES ' .
                ' (' . join( ', ', map { if ( ref($_) eq 'SCALAR' ) { $$_ } elsif ( ref($_) eq 'HASH' ) { my ($module) = keys(%$_); my ($method) = values(%$_); $self->$module->$method(); } else { $self->database->handle->quote($_) } } values %$params ) . ')';
    $self->database->handle->do($query) or warn $DBI::errstr;

    return $self->find( $self->database->last_insert_id() );
}

sub find {
    my ( $self, $key_id ) = @_;
    
    return $self->search_one({
        $self->primary_key => $key_id
    });
}

sub search {
    my ( $self, $search_data ) = @_;
    
    my $columns = $self->columns;
    my $query = 'SELECT ';
    if ( $search_data->{'_select'} ) {
        $query .= $search_data->{'_select'};
        $columns = [];
        foreach my $select ( split( /\s*,\s*/, $search_data->{'_select'} ) ) {
            push( @$columns, 'column_' . ( @$columns + 1 ) );
        }
    } else {
        $query .= join( ', ', @{ $self->columns } );
    }
    $query .= ' FROM ' . $self->table_name;
    my @wheres;
    foreach my $column ( keys %$search_data ) {
        next if ( $column =~ /^_/ );
        if ( ref( $search_data->{$column} ) eq 'HASH' ) {
            push( @wheres, $column . ' LIKE ' . $self->database->handle->quote( $search_data->{$column}->{'LIKE'} ) );
        } else {
            push( @wheres, $column . ' = ' . $self->database->handle->quote( $search_data->{$column} ) );
        }
    }
    $query .= ' WHERE ' . join( ' AND ', @wheres ) if (@wheres);
    $query .= ' ORDER BY ' . $search_data->{'_order_by'} if ( $search_data->{'_order_by'} );
    $query .= ' LIMIT ' . $search_data->{'_limit'} if ( $search_data->{'_limit'} );
    
    my @results;
    my $sth = $self->database->handle->prepare($query);
    $sth->execute();
    if ( $search_data->{'_select'} ) {   
        while ( my @record = $sth->fetchrow_array() ) {
            push(
                @results,
                whatbot::Database::Table::Row->new(
                    'base_component' => $self->base_component,
                    'primary_key'    => $self->primary_key,
                    'table'          => $self->table_name,
                    'columns'        => $columns,
                    'column_data'    => \@record
                )
            );
        }
    } else {        
        while ( my $record = $sth->fetchrow_hashref() ) {
            push(
                @results,
                whatbot::Database::Table::Row->new(
                    'base_component' => $self->base_component,
                    'primary_key'    => $self->primary_key,
                    'table'          => $self->table_name,
                    'columns'        => $columns,
                    'column_data'    => [ map { $record->{$_} } @$columns ]
                )
            );
        }
    }
    return \@results;
}

sub search_one {
    my ( $self, $search_data ) = @_;
    
    my $rows = $self->search($search_data);
    return $rows->[0] if ( @$rows );
    return;
}

sub _make_table {
    my ( $self, $table_data ) = @_;
        
    my $query = 'CREATE TABLE ' . $table_data->{'name'} . ' (';
    
    # Primary Key
    if ( $table_data->{'primary_key'} ) {
        warn 'What the hell, primary key specified but not given in column data.' unless ( $table_data->{'columns'}->{ $table_data->{'primary_key'} } );
        my $column_data = $table_data->{'columns'}->{ $table_data->{'primary_key'} };
        my $type = $column_data->{'type'};
        $query .= $table_data->{'primary_key'} . ' ' . $self->database->$type( $column_data->{'size'} or undef ) . ' primary key, ';
        delete( $table_data->{'columns'}->{ $table_data->{'primary_key'} } );
    }

    # Other Columns
    foreach my $column ( keys %{ $table_data->{'columns'} } ) {
        my $column_data = $table_data->{'columns'}->{$column};
        my $type = $column_data->{'type'};
        $query .= $column . ' ' . $self->database->$type( $column_data->{'size'} or undef ) . ', ';
    }
    
    # Close Query
    $query = substr( $query, 0, length($query) - 2 );
    $query .= ')';
    $self->database->handle->do($query) or warn 'DBI: ' . $DBI::errstr . '  Query: ' . $query;
}

1;

=pod

=head1 NAME

whatbot::Database::Table - Class wrapper for a database table

=head1 SYNOPSIS

 my $table = whatbot::Database::Table->new();
 $table->init_table({});
 $table->create({});

=head1 DESCRIPTION

whatbot::Database::Table wraps a database table into a simple class to add
and return data from. To generate a class for a given table, pass 'init_table'
to a new Table object with the table name and column definitions. If the table
doesn't exist in the database, it will be auto created for you. Once the object
is live, 'create' and 'search' methods are available to add and retrieve rows
(L<whatbot::Database::Table::Row>) from the database. To delete or update data,
perform those actions directly on the returned rows.

=head1 METHODS

=over 4

=item init_table( \%table_params )

Create a new table definition.

=item create( \%column_data )

Create a new row in this table. The passed hashref should contain the column
names as keys, with the desired data in values. Any column not listed in the
hashref will be filled by the corresponding entry in init_table's 'defaults' if
available, or will be left to the database to decide. Returns a
L<whatbot::Database::Table::Row> object if successful, undef on failure.

=item delete()

Delete this record from the database.

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Database

=over 4

=item whatbot::Database::Table

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut