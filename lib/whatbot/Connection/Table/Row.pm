###########################################################################
# whatbot/Connection/Table/Row.pm
###########################################################################
# Class wrapper for a database table row.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Connection::Table::Row;
use Moose;
extends 'whatbot::Component';

has 'primary_key' => ( is => 'rw', isa => 'Str' );
has 'table'       => ( is => 'rw', isa => 'Str' );
has 'columns'     => ( is => 'rw', isa => 'ArrayRef' );
has 'column_data' => ( is => 'rw', isa => 'ArrayRef' );
has 'column_hash' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'changed'     => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

sub BUILD {
    my ( $self ) = @_;
    
    $self->_fill();
}

sub delete {
    my ( $self ) = @_;
    
    unless ( $self->primary_key ) {
        warn 'Sorry, I suck, I am not sure how to delete a row without a pkey.';
        return;
    }
    my $sth = $self->connection->handle->do(
        'DELETE FROM ' . $self->table . ' WHERE ' .
        $self->primary_key . ' = ' . $self->connection->handle->quote( $self->column_hash->{ $self->primary_key } )
    ) or warn $DBI::errstr;
}

sub save {
    my ( $self ) = @_;
    
    unless ( $self->primary_key ) {
        warn 'Sorry, I suck, I am not sure how to delete a row without a pkey.';
        return;
    }
    my $sth = $self->connection->handle->do(
        'UPDATE ' . $self->table . 
        ' SET ' . join( ', ', map { $_ . ' = ' . $self->connection->handle->quote( $self->column_hash->{$_} ) } keys %{ $self->changed } ) .
        ' WHERE ' . $self->primary_key . ' = ' . $self->connection->handle->quote( $self->column_hash->{ $self->primary_key } )
    ) or warn $DBI::errstr;
}

sub _fill {
    my ( $self ) = @_;
    
    for ( my $i = 0; $i < scalar(@{ $self->columns }); $i++ ) {
        my $column = $self->columns->[$i];
        $self->_create_column_accessor($column); 
        if ( $self->column_data->[$i] ) {
            $self->$column( $self->column_data->[$i] );
            $self->column_hash->{$column} = $self->column_data->[$i];
        }
    }
}

sub _fill_array {
    my ( $self ) = @_;
    
    for ( my $i = 0; $i < scalar(@{ $self->columns }); $i++ ) {
        my $column = $self->columns->[$i];
        $self->column_data->[$i] = $self->column_hash->{$column};
    }
}

sub _create_column_accessor {
    my ( $self, $name ) = @_;
    
    no warnings 'redefine';
    eval "sub $name { my ( \$self, \$value ) = \@_; if (\$value) { \$self->column_hash->{$name} = \$value; \$self->changed->{$name} = 1; } \$self->_fill_array(); return \$self->column_hash->{$name}; }";
}

1;