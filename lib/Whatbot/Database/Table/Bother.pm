###########################################################################
# Bother.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Database::Table::Bother - Database functionality for bother.

=head1 DESCRIPTION

Whatbot::Database::Table::Bother provides database functionality for bother.

=head1 METHODS

=over 4

=cut

class Whatbot::Database::Table::Bother extends Whatbot::Database::Table {
	method BUILD(...) {
		$self->init_table({
			'name'        => 'bother',
			'primary_key' => 'bother_id',
			'indexed'     => ['user'],
			'defaults'    => {
				'timestamp'    => { 'database' => 'now' },
				'acknowledged' => 0,
			},
			'columns'     => {
				'bother_id' => {
					'type'  => 'serial'
				},
				'timestamp' => {
					'type'  => 'integer'
				},
				'user' => {
					'type'  => 'varchar',
					'size'  => 255
				},
				'about' => {
					'type'  => 'text'
				},
				'every' => {
					'type'  => 'integer'
				},
				'origin' => {
					'type'  => 'varchar',
					'size'  => 255,
				},
				'acknowledged' => {
					'type'  => 'integer'
				}
			}
		});
	}

=item add($user, $about, $every)

Add a new bother, requires a username, what to bother them about, and the number
of seconds between bothers.

=cut

	method add( $user!, $about!, Int $every!, $origin! ) {
		$self->create({
			'user'   => $user,
			'about'  => $about,
			'every'  => $every,
			'origin' => $origin,
		});
	}

=item acknowledge($user, $about)

Mark an existing bother as acknowledged by setting to the current timestamp.
Returns true if a save occurred.

=cut

	method acknowledge( $user, $about ) {
		my $object = $self->search_one({
			'user'      => $user,
			'about'     => $about,
		});
		if ($object) {
			$object->acknowledged(time);
			$object->save();
			return 1;
		}
		return;
	}

=item acknowledge_all_for($user)

Mark all active bothers for a user as acknowledged by setting to the current
timestamp. Returns all bothers acknowledged.

=cut

	method acknowledge_all_for( $user! ) {
		my $bothers = $self->get_active_for($user);
		foreach my $bother (@$bothers) {
			$self->acknowledge( $bother->user, $bother->about );
		}
		return $bothers;
	}

=item get_active()

Retrieve all active bothers -- bothers that are unacknowledged.

=cut

	method get_active() {
		return $self->search({
			'acknowledged' => { '<' => 1 },
		});
	}

=item get_active_for($user)

Retrieve all active bothers -- bothers that are unacknowledged -- for a user.

=cut

	method get_active_for($user!) {
		return $self->search({
			'user'         => $user,
			'acknowledged' => { '>' => 0 },
		});

	}

=item get($user, $about)

Get an individual bother by user and about.

=cut

	method get( $user!, $about! ) {
		return $self->search_one({
			'user'  => $user,
			'about' => $about,
		});
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
