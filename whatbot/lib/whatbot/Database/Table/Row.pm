###########################################################################
# whatbot/Database/Table/Row.pm
###########################################################################
# Class wrapper for a database table row.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Database::Table::Row;
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
    my $sth = $self->database->handle->do(
        'DELETE FROM ' . $self->table . ' WHERE ' .
        $self->primary_key . ' = ' . $self->database->handle->quote( $self->column_hash->{ $self->primary_key } )
    ) or warn $DBI::errstr;
}

sub save {
    my ( $self ) = @_;
    
    unless ( $self->primary_key ) {
        warn 'Sorry, I suck, I am not sure how to save a row without a pkey.';
        return;
    }
    delete ( $self->changed->{ $self->primary_key } );
    my $sth = $self->database->handle->do(
        'UPDATE ' . $self->table . 
        ' SET ' . join( ', ', map { $_ . ' = ' . $self->database->handle->quote( $self->column_hash->{$_} ) } keys %{ $self->changed } ) .
        ' WHERE ' . $self->primary_key . ' = ' . $self->database->handle->quote( $self->column_hash->{ $self->primary_key } )
    ) or warn $DBI::errstr;
}

sub _fill {
    my ( $self ) = @_;
    
    for ( my $i = 0; $i < scalar(@{ $self->columns }); $i++ ) {
        my $column = $self->columns->[$i];
        $self->_create_column_accessor($column); 
        if ( $self->column_data->[$i] ) {
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
    eval "sub $name { my ( \$self, \$value ) = \@_; if ( defined \$value ) { \$self->column_hash->{$name} = \$value; \$self->changed->{$name} = 1; } \$self->_fill_array(); return \$self->column_hash->{$name}; }";
}

1;

=pod

=head1 NAME

whatbot::Database::Table::Row - Class wrapper for a database table row

=head1 SYNOPSIS

 my $row = $table->find(1);
 $row->row_id;

=head1 DESCRIPTION

whatbot::Database::Table::Row wraps a record/row from a database result in
an easy to use class. Each column in the record will auto-generate an accessor
to be able to retrieve and set values. Call 'delete' to delete the given row,
and call 'save' to update the row with new values. You cannot change the
primary key at this time.

=head1 METHODS

=over 4

=item save

Saves changes made back to the database.

=item delete

Delete this record from the database.

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Database::Table::Row

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut