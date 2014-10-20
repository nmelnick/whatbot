###########################################################################
# Whatbot/Database/SQLite.pm
###########################################################################
# SQLite Connection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

Whatbot::Database::SQLite - Connect whatbot to a SQLite database.

=cut

class Whatbot::Database::SQLite extends Whatbot::Database::DBI {

	before connect() {
		die 'SQLite requires a database name.' unless ( $self->config->database->{'database'} );

		$self->connect_array([
			'DBI:SQLite:dbname=' . $self->config->database->{'database'},
			'',
			'',
			{
				'sqlite_use_immediate_transaction' => 1,
				'sqlite_unicode' => 1,
				'AutoCommit' => 1,
			}
		]);
	}

	method last_insert_id( $table_name ) {
		return $self->handle->func('last_insert_rowid');
	}

	method timestamp() {
		return 'integer';
	}

	method serial ( $null? ) {
		$self->postfix(1);
		return $self->integer();
	}

	method now() {
		return $self->handle->quote(time);
	}

	method serial_postfix() {
		return 'autoincrement';
	}

}

1;

=pod

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
