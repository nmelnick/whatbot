###########################################################################
# Soup.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

Whatbot::Database::Table::Soup - Allows commands access to a data "soup".

=head1 SYNOPSIS

 use Whatbot::Database::Table::Soup;

=head1 DESCRIPTION

Whatbot::Database::Table::Soup allows commands to have access to a data "soup". This
provides simple key->value database support to commands that don't require
multiple column relationships. Handy for preferences, or simple data point
updates. Auto handles update-or-create, expunging entries, etc.

=head1 METHODS

=over 4

=cut

class Whatbot::Database::Table::Soup extends Whatbot::Database::Table {
	has 'module' => ( is => 'rw', isa => 'Whatbot::Database::Table' );

	method BUILD(...) {
		$self->init_table({
			'name'        => 'soup',
			'primary_key' => 'soup_id',
			'indexed'     => [ 'module_id', 'subject' ],
			'columns'     => {
				'soup_id' => {
					'type'  => 'serial',
				},
				'module_id' => {
					'type'  => 'integer',
				},
				'subject' => {
					'type'  => 'varchar',
					'size'  => 255
				},
				'value' => {
					'type'  => 'text'
				}
			}
		});
		my $module = Whatbot::Database::Table->new();
		$module->init_table({
			'name'        => 'soup_module',
			'primary_key' => 'module_id',
			'indexed'     => ['name'],
			'columns'     => {
				'module_id' => {
					'type'  => 'serial'
				},
				'name' => {
					'type'  => 'varchar',
					'size'  => 255
				},
			}
		});
		$self->module($module);
	}

	method _get_module( $caller, ... ) {
		my $module = $self->module->search_one({
			'name' => $caller
		});
		if ($module) {
			return $module->module_id;
		} else {
			$module = $self->module->create({
				'name' => $caller
			});
			return $module->module_id;
		}

		return;
	}

=item set( $key, $value )

Set a key/value pair. Auto creates an entry if it doesn't exist, or updates
the existing entry. Returns the new value as set.

=cut

	method set( Str $key, Str $value ) {
		my $row = $self->search_one({
			'module_id' => $self->_get_module( caller() ),
			'subject'   => $key
		});
		if ($row) {
			$row->value($value);
			$row->save();
		} else {
			$row = $self->create({
				'module_id' => $self->_get_module( caller() ),
				'subject'   => $key,
				'value'     => $value
			});
		}

		return $row->value;
	}

=item get( $key )

Get a value for the specified key. Returns undef if the key doesn't exist in
the database.

=cut

	method get( Str $key ) {
		my $row = $self->search_one({
			'module_id' => $self->_get_module( caller() ),
			'subject'   => $key
		});
		if ($row) {
			return $row->value;
		}
		return;
	}

=item clear( $key )

Clear key from storage.

=cut

	method clear( Str $key ) {
		my $row = $self->search_one({
			'module_id' => $self->_get_module( caller() ),
			'subject'   => $key
		});
		if ($row) {
			$row->delete;
		}
		return;
	}

=item get_hashref()

Get all pairs for the current module. Returns a hashref of the key-value pairs.

=cut

	method get_hashref() {
		my $rows = $self->search({
			'module_id' => $self->_get_module( caller() )
		});
		my %results;
		foreach my $row (@$rows) {
			$results{ $row->subject } = $row->value;
		}
		return \%results;
	}

=item get_count()

Return number of entries for this module.

=cut

	method get_count() {
		return $self->count({
			'module_id' => $self->_get_module( caller() )
		});
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
