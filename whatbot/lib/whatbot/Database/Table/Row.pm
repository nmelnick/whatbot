###########################################################################
# Row.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

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

=cut

class whatbot::Database::Table::Row extends whatbot::Component {
    has 'primary_key' => ( is => 'rw', isa => 'Str' );
    has 'table'       => ( is => 'rw', isa => 'Str' );
    has 'columns'     => ( is => 'rw', isa => 'ArrayRef' );
    has 'column_data' => ( is => 'rw', isa => 'ArrayRef' );
    has 'column_hash' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
    has 'changed'     => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

    method BUILD(...) {
        $self->_fill();
    }

=item delete()

Delete this record from the database.

=cut

    method delete() {
        unless ( $self->primary_key ) {
            warn 'Sorry, I suck, I am not sure how to delete a row without a pkey.';
            return;
        }
        my $query = sprintf(
            'DELETE FROM %s WHERE %s = %s',
            $self->table,
            $self->database->handle->quote_identifier( $self->primary_key ),
            $self->database->handle->quote( $self->column_hash->{ $self->primary_key } ),
        );
        if ( $ENV{'WB_DATABASE_DEBUG'} ) {
            $self->log->write($query);
        }
        $self->database->handle->do($query) or warn $DBI::errstr;
    }

=item save()

Saves changes made back to the database.

=cut

    method save() {
        unless ( $self->primary_key ) {
            warn 'Sorry, I suck, I am not sure how to save a row without a pkey.';
            return;
        }
        delete ( $self->changed->{ $self->primary_key } );
        my $query = 
            'UPDATE ' . $self->table . 
            ' SET ' . join( ', ', map { $self->database->handle->quote_identifier($_) . ' = ' . $self->database->handle->quote( $self->column_hash->{$_} ) } keys %{ $self->changed } ) .
            ' WHERE ' . $self->database->handle->quote_identifier( $self->primary_key ) . ' = ' . $self->database->handle->quote( $self->column_hash->{ $self->primary_key } );
        
        if ( $ENV{'WB_DATABASE_DEBUG'} ) {
            $self->log->write($query);
        }

        my $sth = $self->database->handle->do($query) or warn $DBI::errstr;
    }

    method _fill() {
        for ( my $i = 0; $i < scalar(@{ $self->columns }); $i++ ) {
            my $column = $self->columns->[$i];
            $self->_create_column_accessor($column); 
            if ( $self->column_data->[$i] ) {
                $self->column_hash->{$column} = $self->column_data->[$i];
            }
        }
    }

    method _fill_array() {
        for ( my $i = 0; $i < scalar(@{ $self->columns }); $i++ ) {
            my $column = $self->columns->[$i];
            $self->column_data->[$i] = $self->column_hash->{$column};
        }
    }

    method _create_column_accessor( Str $name ) {
        no warnings 'redefine';
        eval "sub $name { my ( \$self, \$value ) = \@_; if ( defined \$value ) { \$self->column_hash->{$name} = \$value; \$self->changed->{$name} = 1; } \$self->_fill_array(); return \$self->column_hash->{$name}; }";
    }
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut