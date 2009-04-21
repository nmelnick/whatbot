###########################################################################
# whatbot/Connection/Table.pm
###########################################################################
# Class wrapper for a database table
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Connection::Table;
use Moose;
extends 'whatbot::Connection';

use whatbot::Connection::Table::Row;

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
    unless ( $self->connection->tables->{ $table_data->{'name'} } ) {
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
                ' (' . join( ', ', map { if ( ref($_) eq 'SCALAR' ) { $$_ } elsif ( ref($_) eq 'HASH' ) { my ($module) = keys(%$_); my ($method) = values(%$_); $self->$module->$method(); } else { $self->handle->quote($_) } } values %$params ) . ')';
    $self->handle->do($query) or warn $DBI::errstr;
    
    return $self->get( $self->connection->last_insert_id() );
}

sub get {
    my ( $self, $key_id ) = @_;
    
    $_ = $self->primary_key;
    return $self->search_one({
        $_ => $key_id
    });
}

sub search {
    my ( $self, $search_data ) = @_;
    
    my $columns = $self->columns;
    my $query = 'SELECT ';
    if ( $search_data->{'_select'} ) {
        $query .= $search_data->{'_select'};
        $columns = [];
        my $col_name = 1;
        foreach my $select ( split( /\s*,\s*/, $search_data->{'_select'} ) ) {
            push( @$columns, 'column_' . $col_name++ );
        }
    } else {
        $query .= join( ', ', @{ $self->columns } );
    }
    $query .= ' FROM ' . $self->table_name;
    my @wheres;
    foreach my $column ( keys %$search_data ) {
        next if ( $column =~ /^_/ );
        if ( ref( $search_data->{$column} ) eq 'HASH' ) {
            push( @wheres, $column . ' LIKE ' . $self->connection->handle->quote( $search_data->{$column}->{'LIKE'} ) );
        } else {
            push( @wheres, $column . ' = ' . $self->connection->handle->quote( $search_data->{$column} ) );
        }
    }
    $query .= ' WHERE ' . join( ' AND ', @wheres ) if (@wheres);
    $query .= ' ORDER BY ' . $search_data->{'_order_by'} if ( $search_data->{'_order_by'} );
    $query .= ' LIMIT ' . $search_data->{'_limit'} if ( $search_data->{'_limit'} );
    
    my @results;
    my $sth = $self->connection->handle->prepare($query);
    $sth->execute();
    if ( $search_data->{'_select'} ) {   
        while ( my @record = $sth->fetchrow_array() ) {
            push(
                @results,
                new whatbot::Connection::Table::Row(
                    'base_component' => $self->parent->base_component,
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
                new whatbot::Connection::Table::Row(
                    'base_component' => $self->parent->base_component,
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
        $query .= $table_data->{'primary_key'} . ' ' . $self->connection->$type( $column_data->{'size'} or undef ) . ' primary key, ';
        delete( $table_data->{'columns'}->{ $table_data->{'primary_key'} } );
    }

    # Other Columns
    foreach my $column ( keys %{ $table_data->{'columns'} } ) {
        my $column_data = $table_data->{'columns'}->{$column};
        my $type = $column_data->{'type'};
        $query .= $column . ' ' . $self->connection->$type( $column_data->{'size'} or undef ) . ', ';
    }
    
    # Close Query
    $query = substr( $query, 0, length($query) - 2 );
    $query .= ')';
    $self->connection->handle->do($query) or warn 'DBI: ' . $DBI::errstr . '  Query: ' . $query;
}

1;