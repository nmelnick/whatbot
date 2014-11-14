###########################################################################
# Whatbot/Database/Table/Lightwire.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class Whatbot::Database::Table::Lightwire extends Whatbot::Database::Table {

    method BUILD(...) {
        $self->init_table({
            'name'        => 'lightwire',
            'primary_key' => 'user',
            'columns'     => {
                'lightwire_portfolio_id' => {
                    'type'  => 'integer'
                },
                'user' => {
                    'type'  => 'varchar',
                    'size'  => 255
                }
            }
        });
    }

    method portfolio_id_for ( Str $user ) {
        my $sth = $self->database->handle->prepare(q{
            SELECT lightwire_portfolio_id
            FROM   lightwire
            WHERE  user = ?
        });
        $sth->execute( $user );
        my ($id) = $sth->fetchrow_array();
        return ( $id or 0 );
    }

    method set_portfolio_id_for ( Str $user, $id ) {
        return $self->create({
            'lightwire_portfolio_id' => $id,
            'user' => $user
        });
    }

}

1;

=pod

=head1 NAME

Whatbot::Database::Table::Lightwire - Database model for Lightwire

=head1 DESCRIPTION

It just stores a lightwire portfolio id for every user seen. wow exciting.

I know it's wrong to use a string as a primary key, but I did it. Sorry,
everyone. This is what IRC does to you.

=head1 INHERITANCE

=over 4

=item Whatbot::Component

=over 4

=item Whatbot::Database::Table

=over 4

=item Whatbot::Database::Table::Trade

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
