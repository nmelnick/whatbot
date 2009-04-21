###########################################################################
# whatbot/Connection/Table/Karma.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Connection::Table::Karma;
use Moose;
extends 'whatbot::Connection::Table';

sub BUILD {
    my ( $self ) = @_;
    
    $self->init_table({
        'name'        => 'karma',
        'primary_key' => 'karma_id',
        'defaults'    => {
            'created'   => { 'connection' => 'now' }
        },
        'columns'     => {
            'karma_id' => {
                'type'  => 'integer'
            },
            'subject' => {
                'type'  => 'varchar',
                'size'  => 255
            },
            'user' => {
                'type'  => 'varchar',
                'size'  => 255
            },
            'created' => {
                'type'  => 'integer'
            },
            'amount' => {
                'type'  => 'integer'
            }
        }
    });
}

sub decrement {
    my ( $self, $topic, $user ) = @_;
    
    $self->create({
        'subject'   => $topic,
        'user'      => $user,
        'amount'    => -1
    });
}

sub increment {
    my ( $self, $topic, $user ) = @_;
    
    $self->create({
        'subject'   => $topic,
        'user'      => $user,
        'amount'    => 1
    });
}

sub get {
    my ( $self, $topic ) = @_;
    
    my $row = $self->search_one({
        '_select' => 'SUM(amount)',
        'subject' => $topic
    });
    return ( $row ? $row->a : '' );
}

sub get_extended {
    my ( $self, $topic ) = @_;
    
    my $increment_row = $self->search_one({
        '_select' => 'COUNT(amount)',
        'subject' => $topic,
        'amount'  => 1
    });
    my $decrement_row = $self->search_one({
        '_select' => 'COUNT(amount)',
        'subject' => $topic,
        'amount'  => -1
    });
    my $last_row = $self->search_one({
        'subject'   => $topic,
        '_order_by' => 'karma_id DESC',
        '_limit'    => 1
    });
    
    return {
        'Increments' => $increment_row->a,
        'Decrements' => $decrement_row->a,
        'Last'       => [
            $last_row->user,
            $last_row->amount
        ]
    };
}

1;

=pod

=head1 NAME

whatbot::Connection::Table::Karma - Database functionality for karma.

=head1 SYNOPSIS

 use whatbot::Connection::Table::Karma;
 my $model = new whatbot::Connection::Table::Karma;
 $model->increment( 'whatbot', 'awesome_guy' );

=head1 DESCRIPTION

whatbot::Connection::Table::Karma provides database functionality for karma.

=head1 METHODS

=over 4

=item increment( $topic, $user )

=item decrement( $topic, $user )

=item get( $topic )

=item get_extended( $topic )

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Connection

=over 4

=item whatbot::Connection::Table

=over 4

=item whatbot::Connection::Table::Karma

=back

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut