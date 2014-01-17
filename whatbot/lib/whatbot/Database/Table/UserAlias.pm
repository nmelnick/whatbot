###########################################################################
# whatbot/Database/Table/UserAlias.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Database::Table::UserAlias - Track user aliases

=head1 SYNOPSIS

 use whatbot::Database::Table::UserAlias;

=head1 DESCRIPTION

whatbot::Database::Table::UserAlias tracks a one user to many aliases
relationship.

=head1 METHODS

=over 4

=cut

class whatbot::Database::Table::UserAlias extends whatbot::Database::Table {
    method BUILD(...) {
        $self->init_table({
            'name'        => 'user_alias',
            'primary_key' => 'user_alias_id',
            'indexed'     => [ 'user' ],
            'columns'     => {
                'user_alias_id' => {
                    'type'  => 'serial',
                },
                'user' => {
                    'type'  => 'varchar',
                    'size'  => 255,
                },
                'alias' => {
                    'type'  => 'varchar',
                    'size'  => 255,
                }
            }
        });
    }

=item alias( $user, $alias )

Set a new alias for a user. If a user isn't being tracked, it will start being
tracked. If the alias already exists, this is a no-op. Returns true on success.

=cut

    method alias( Str $user, Str $alias ) {
        $user = lc($user);
        $alias = lc($alias) or return;
        my $row = $self->search_one({
            'user'  => $user,
            'alias' => $alias,
        });
        unless ($row) {
            $row = $self->create({
                'user'  => $user,
                'alias' => $alias,
            });
            return $row;
        }
        return;
    }

=item user_for_alias( $alias )

Return a username attached to the given alias. Returns nothing if the alias is
not found.

=cut

    method user_for_alias( Str $alias ) {
        my $row = $self->search_one({
            'alias' => $alias,
        });
        if ($row) {
            return $row->user;
        }
        return;
    }

=item aliases_for_user( $user )

Return an arrayref of aliases for the given user.

=cut

    method aliases_for_user( Str $user ) {
        my $rows = $self->search({
            'user' => $user,
        });
        if ($rows) {
            return [ map { $_->alias } @$rows ];
        }
        return;
    }

=item related_users( $user_or_alias )

Retrieve all related users for this string, which could be other aliases or
an attached user.

=cut

    method related_users( Str $user_or_alias ) {
        my @users;
        my $aliases = $self->aliases_for_user($user_or_alias);
        if ($aliases) {
            push( @users, @$aliases );
        }
        my $user = $self->user_for_alias($user_or_alias);
        if ($user) {
            push( @users, $user );
        }
        return \@users;
    }

=item canonical_user( $user_or_alias )

Like user_for_alias, returns a username attached to the given alias if one
exists, but returns the alias if a parent username is not found.

=cut

    method canonical_user( Str $user ) {
        my $lcuser = lc($user) or return;
        return ( $self->user_for_alias($lcuser) or $user );
    }

=item remove( $user, $alias? )

Remove an alias from a user. If no alias is provided, removes everything for
that user. Returns true on success.

=cut

    method remove( Str $user, Str $alias? ) {
        $user = lc($user);
        if ($alias) {
            $alias = lc($alias);
            my $row = $self->search_one({
                'user'  => $user,
                'alias' => $alias,
            });
            if ($row) {
                $row->delete();
                return 1;
            }
        } else {
            my $rows = $self->search({
                'user'  => $user,
            });
            if ($rows) {
                foreach (@$rows) {
                    $_->delete();
                }
                return 1;
            }
        }
        return;
    }
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
