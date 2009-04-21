###########################################################################
# whatbot/Connection/Table/Factoid.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Connection::Table::Factoid;
use Moose;
extends 'whatbot::Connection::Table';

has 'description' => ( is => 'rw', isa => 'whatbot::Connection::Table' );
has 'ignore'      => ( is => 'rw', isa => 'whatbot::Connection::Table' );

sub BUILD {
    my ( $self ) = @_;
    
    $self->init_table({
        'name'        => 'factoid',
        'primary_key' => 'factoid_id',
        'defaults'    => {
            'created'   => { 'connection' => 'now' },
            'updated'   => { 'connection' => 'now' }
        },
        'columns'     => {
            'factoid_id' => {
                'type'        => 'integer'
            },
            'is_or'      => {
                'type'        => 'integer'
            },
            'is_plural'  => {
                'type'        => 'integer'
            },
            'created'    => {
                'type'        => 'integer'
            },
            'updated'    => {
                'type'        => 'integer'
            },
            'silent' => {
                'type'        => 'integer'
            },
            'subject' => {
                'type'        => 'varchar',
                'size'        => 255
            },
        }
    });

    my $description = new whatbot::Connection::Table(
        'base_component' => $self->parent->base_component
    );
    $description->init_table({
        'name'        => 'factoid_description',
        'defaults'    => {
            'created'   => { 'connection' => 'now' },
            'updated'   => { 'connection' => 'now' }
        },
        'columns'     => {
            'factoid_id' => {
                'type'  => 'integer'
            },
            'updated'      => {
                'type'  => 'integer'
            },
            'hash'  => {
                'type'  => 'char',
                'size'  => 40
            },
            'user'    => {
                'type'  => 'varchar',
                'size'  => 255
            },
            'description'    => {
                'type'  => 'text'
            }
        }
    });
    my $ignore = new whatbot::Connection::Table(
        'base_component' => $self->parent->base_component
    );
    $ignore->init_table({
        'name'        => 'factoid_ignore',
        'primary_key' => 'subject',
        'columns'     => {
            'subject' => {
                'type'        => 'varchar',
                'size'        => 255
            },
        }
    });
    
    $self->description($description);
    $self->ignore($ignore);
}


1;

=pod

=head1 NAME

whatbot::Connection::Table::Factoid - Database functionality for factoids.

=head1 SYNOPSIS

 use whatbot::Connection::Table::Factoid;

=head1 DESCRIPTION

whatbot::Connection::Table::Factoid provides database functionality for factoids.

=head1 PUBLIC ACCESSORS

=over 4

=item 1

2.

=back

=head1 METHODS

=over 4

=item 1

2

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Connection::Table

=over 4

=item whatbot::Connection::Table::Factoid

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut