###########################################################################
# Table.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Database::Table - Class wrapper for a database table

=head1 SYNOPSIS

 class Whatbot::Database::Table::ATable extends Whatbot::Database::Table {
   sub BUILD(...) {
	 $table->init_table({
		'name'        => 'a_table',
		'primary_key' => 'a_table_id',
		'indexed'     => ['thing'],
		'columns'     => {
			'a_table_id' => {
				'type' => 'serial'
			},
			'thing' => {
				'type' => 'varchar',
				'size' => 32
			},
		},
	 });
	 $table->create({
		'thing' => 'Test',
	 });
   }
 }

=head1 DESCRIPTION

Whatbot::Database::Table wraps a database table into a simple class to add
and return data from. To generate a class for a given table, pass 'init_table'
to a new Table object with the table name and column definitions. If the table
doesn't exist in the database, it will be auto created for you. Once the object
is live, 'create' and 'search' methods are available to add and retrieve rows
(L<Whatbot::Database::Table::Row>) from the database. To delete or update data,
perform those actions directly on the returned rows.

=head1 METHODS

=over 4

=cut

class Whatbot::Database::Table extends Whatbot::Database {
	use Whatbot::Database::Table::Row;
	use Clone qw(clone);

	has 'table_name'    => ( is => 'rw', isa => 'Str' );
	has 'primary_key'   => ( is => 'rw', isa => 'Maybe[Str]' );
	has 'columns'       => ( is => 'rw', isa => 'ArrayRef' );
	has 'defaults'      => ( is => 'rw', isa => 'HashRef' );
	# has 'column_info'   => ( is => 'rw', isa => 'HashRef' );

=item init_table( \%table_params )

Create a new table definition, generally called in BUILD. Possible keys are:

=over 4

=item name

Table name, as it should be referred to in the data store.

=item primary_key

Optional. The primary key name in the table.

=item columns

A hashref, where the key is the column name, and the value is another hashref
containing a "type", and optionally, a "size". For example:

 columns => {
   'a_column' => {
	 'type' => 'varchar',
	 'size' => 32,
   }
 }

=item defaults

Optional. A hashref where the key is a column name, and the value is a default
value for that column on create.

=back

=cut

	method init_table ($table_data) {
		warn 'Missing name for table' unless ( $table_data->{'name'} );
		warn 'Missing column data for table' unless ( $table_data->{'columns'} );
		
		# Create table if it doesn't exist
		unless ( $self->database and $self->database->tables->{ $table_data->{'name'} } ) {
			$self->log->write('Creating table "' . $table_data->{'name'} . '" for ' . caller() . '.' );
			$self->_make_table($table_data);
		}
		
		$self->table_name( $table_data->{'name'} );
		$self->primary_key( $table_data->{'primary_key'} ) if ( $table_data->{'primary_key'} );
		$self->columns([ keys %{ $table_data->{'columns'} } ]);
		$self->defaults( $table_data->{'defaults'} or {} );
		# $self->column_info( $table_data->{'columns'} );
	}

=item create( \%column_data )

Create a new row in this table. The passed hashref should contain the column
names as keys, with the desired data in values. Any column not listed in the
hashref will be filled by the corresponding entry in init_table's 'defaults' if
available, or will be left to the database to decide. Returns a
L<Whatbot::Database::Table::Row> object if successful, undef on failure.

=cut

	method create ($column_data) {
		my $params;
		foreach ( keys %{ $self->defaults } ) {
			$params->{$_} = $self->defaults->{$_};
		}
		foreach ( keys %$column_data ) {
			$params->{$_} = $column_data->{$_};
		}
		my $query = 'INSERT INTO ' . $self->table_name .
					' (' . join( ', ', ( map { $self->database->handle->quote_identifier($_) } keys %$params ) ) . ') ' .
					'VALUES ' .
					' (' . join( ', ', map {
						if ( ref($_) eq 'SCALAR' ) {
							${$$_};
						} elsif ( ref($_) eq 'HASH' ) {
							my ($module) = keys(%$_);
							my ($method) = values(%$_);
							$self->$module->$method();
						} else {
							$self->database->handle->quote($_);
						}
					} values %$params ) . ')';

		if ( $ENV{'WB_DATABASE_DEBUG'} ) {
			$self->log->write($query);
		}

		$self->database->handle->do($query) or warn 'Error executing query [[' . $query . ']], error: ' . $DBI::errstr;

		return $self->find( $self->database->last_insert_id( $self->table_name ) );
	}

=item find($key_id)

Search the table to find the given value in the primary key column. Returns
nothing if not found.

=cut

	method find ($key_id) {
		return $self->search_one({
			$self->primary_key => $key_id
		});
	}

=item count(<\%search_data>)

Return the number of rows in the table. Can be filtered with a search query
similar to what would be sent to search_one() or search().

=cut

	method count ($search_data?) {
		$search_data->{'_select'} = 'COUNT(*) AS column_1';
		my $result = $self->search($search_data);
		return $result->[0]->{'column_data'}->[0];
	}

=item search(<\%search_data>)

Search the table and return results. The optional search_data hashref allows
filtering of the results. Return an empty arrayref if no results are found, or
an arrayref of L<Whatbot::Database::Table::Row> instances. The search_data
hashref can contain key => value pairs that correspond to a column name and a
value for equal searches, otherwise, a value can be a hashref that contains a
key of 'LIKE' and a value of the like query. Keys that start with underscore
are reserved, and can include:

=over 4

=item _select

Select a specific set of columns in the given arrayref, rather than all columns.

=item _order_by

A fully qualified order by clause.

=item _limit

Limit to a given number of rows.

=back

=cut

	method search ($search_data?) {
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
				push(
					@wheres, 
					sprintf( '%s LIKE %s',
						$self->database->handle->quote_identifier($column),
						$self->database->handle->quote( $search_data->{$column}->{'LIKE'} )
					)
				);
			} else {
				push(
					@wheres, 
					sprintf( '%s = %s',
						$self->database->handle->quote_identifier($column),
						$self->database->handle->quote( $search_data->{$column} )
					)
				);
			}
		}
		$query .= ' WHERE ' . join( ' AND ', @wheres ) if (@wheres);
		$query .= ' ORDER BY ' . $search_data->{'_order_by'} if ( $search_data->{'_order_by'} );
		$query .= ' LIMIT ' . $search_data->{'_limit'} if ( $search_data->{'_limit'} );

		if ( $ENV{'WB_DATABASE_DEBUG'} ) {
			$self->log->write($query);
		}

		my @results;
		my $sth = $self->database->handle->prepare($query);
		$sth->execute();
		if ( $search_data->{'_select'} ) {   
			while ( my @record = $sth->fetchrow_array() ) {
				push(
					@results,
					Whatbot::Database::Table::Row->new(
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
					Whatbot::Database::Table::Row->new(
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

=item search_one(<\%search_data>)

Search the table and return one L<Whatbot::Database::Table::Row> instance, or
nothing if it is not found.

=cut

	method search_one ($search_data?) {
		my $rows = $self->search($search_data);
		return $rows->[0] if ( @$rows );
		return;
	}

	method _make_table ($table_data) {
		my $query = 'CREATE TABLE ' . $table_data->{'name'} . ' (';
		
		my $local_columns = clone( $table_data->{'columns'} );
		# Primary Key
		if ( $table_data->{'primary_key'} ) {
			warn 'Primary key specified but not given in column data.' unless ( $local_columns->{ $table_data->{'primary_key'} } );
			my $column_data = $local_columns->{ $table_data->{'primary_key'} };
			my $type = $column_data->{'type'};
			$query .= sprintf(
				'%s %s primary key %s, ',
				$self->database->handle->quote_identifier( $table_data->{'primary_key'} ),
				$self->database->$type( $column_data->{'size'} or undef ),
				( $type eq 'serial' and $self->database->postfix ? $self->database->serial_postfix() : '' ),
			);
			delete( $local_columns->{ $table_data->{'primary_key'} } );
		}

		# Other Columns
		foreach my $column ( keys %{$local_columns} ) {
			my $column_data = $local_columns->{$column};
			my $type = $column_data->{'type'};
			$query .= $self->database->handle->quote_identifier($column) . ' ' . $self->database->$type( $column_data->{'size'} or undef ) . ', ';
		}
		
		# Close Query
		$query = substr( $query, 0, length($query) - 2 );
		$query .= ')';
		if ( $ENV{'WB_DATABASE_DEBUG'} ) {
			$self->log->write($query);
		}
		$self->database->handle->do($query) or warn 'DBI: ' . $DBI::errstr . '  Query: ' . $query;

		# Index
		if ( $table_data->{'indexed'} ) {
			foreach my $indexed_column ( @{ $table_data->{'indexed'} } ) {
				my $index_name = 'idx_' . $table_data->{'name'} . '_' . $indexed_column;
				$query = sprintf(
					'CREATE INDEX %s ON %s (%s)',
					$index_name,
					$table_data->{'name'},
					$self->database->handle->quote_identifier($indexed_column)
				);
				$self->database->handle->do($query) or warn 'DBI: ' . $DBI::errstr . '  Query: ' . $query;
			}
		}

		$self->database->get_tables();
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut