###########################################################################
# whatbot/Database/Table/UserAlias.pm
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::Database::Table::UserAlias extends whatbot::Database::Table {
    method BUILD(...) {
        my ( $self ) = @_;
        
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

    method alias( Str $user, Str $alias ) {
        $user = lc($user);
        $alias = lc($alias);
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

    method remove( Str $user, Str $alias ) {
        $user = lc($user);
        $alias = lc($alias);
        my $row = $self->search_one({
            'user'  => $user,
            'alias' => $alias,
        });
        if ($row) {
            $row->delete();
            return 1;
        }
        return;
    }
}

1;

=pod

=head1 NAME

whatbot::Database::Table::UserAlias - Track user aliases

=head1 SYNOPSIS

 use whatbot::Database::Table::UserAlias;

=head1 DESCRIPTION

whatbot::Database::Table::UserAlias tracks a one user to many aliases
relationship.

=head1 METHODS

=over 4

=item alias( $user, $alias )

Set a new alias for a user. If a user isn't being tracked, it will start being
tracked. If the alias already exists, this is a no-op. Returns true on success.

=item remove( $user, $alias )

Remove an alias from a user. If no alias is provided, removes everything for
that user. Returns true on success.

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Database::Table

=over 4

=item whatbot::Database::Table::Soup

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
