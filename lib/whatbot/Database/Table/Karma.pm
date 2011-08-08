###########################################################################
# whatbot/Database/Table/Karma.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Database::Table::Karma;
use Moose;
extends 'whatbot::Database::Table';

sub BUILD {
    my ( $self ) = @_;
    
    $self->init_table({
        'name'        => 'karma',
        'primary_key' => 'karma_id',
        'defaults'    => {
            'created'   => { 'database' => 'now' }
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
        'subject' => lc($topic)
    });
    return ( $row ? $row->column_data->[0] : '' );
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
    
    return $last_row ? {
        'Increments' => $increment_row->column_data->[0],
        'Decrements' => $decrement_row->column_data->[0],
        'Last'       => [
            $last_row->user,
            $last_row->amount
        ]
    } : undef;
}

1;

=pod

=head1 NAME

whatbot::Database::Table::Karma - Database functionality for karma.

=head1 SYNOPSIS

 use whatbot::Database::Table::Karma;
 my $model = whatbot::Database::Table::Karma->new();
 $model->increment( 'whatbot', 'awesome_guy' );

=head1 DESCRIPTION

whatbot::Database::Table::Karma provides database functionality for karma.

=head1 METHODS

=over 4

=item increment( $topic, $user )

Increment the karma on a topic.

=item decrement( $topic, $user )

Decrement the karma on a topic.

=item get( $topic )

Retrieve the karma on a topic.

=item get_extended( $topic )

Retrieve extended info on a topic's karma. Returns a hashref containing
'Increments', which is the total volume of increments, 'Decrements',
containing the total volume of decrements, and 'Last', which is an arrayref
containing the last changing user and the amount of karma given.

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Database

=over 4

=item whatbot::Database::Table

=over 4

=item whatbot::Database::Table::Karma

=back

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
