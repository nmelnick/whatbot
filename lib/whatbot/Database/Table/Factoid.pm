###########################################################################
# whatbot/Database/Table/Factoid.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Database::Table::Factoid;
use Moose;
extends 'whatbot::Database::Table';

has 'description' => ( is => 'rw', isa => 'whatbot::Database::Table' );
has 'ignore'      => ( is => 'rw', isa => 'whatbot::Database::Table' );

sub BUILD {
    my ( $self ) = @_;
    
    $self->init_table({
        'name'        => 'factoid',
        'primary_key' => 'factoid_id',
        'defaults'    => {
            'created'   => { 'database' => 'now' },
            'updated'   => { 'database' => 'now' }
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

    my $description = new whatbot::Database::Table(
        'base_component' => $self->parent->base_component
    );
    $description->init_table({
        'name'        => 'factoid_description',
        'defaults'    => {
            'created'   => { 'database' => 'now' },
            'updated'   => { 'database' => 'now' }
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
    my $ignore = new whatbot::Database::Table(
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

sub is_silent {
    my ( $self, $subject ) = @_;
    
    return unless ($subject);
    $subject = lc($subject);
    
    my $factoid = $self->search_one({
        'subject' => $subject
    });
    if ($factoid) {
        return $factoid->silent;
    }
    
    return;
}

sub silence {
    my ( $self, $subject ) = @_;
    
    return unless ($subject);
    $subject = lc($subject);
    
    my $factoid = $self->search_one({
        'subject' => $subject
    });
    if ($factoid) {
        if ( $factoid->silent ) {
            $factoid->silent(0);
        } else {
            $factoid->silent(1);
        }
        $factoid->save();
    }
    
    return $self->is_silent($subject);
}

1;

=pod

=head1 NAME

whatbot::Database::Table::Factoid - Database functionality for factoids.

=head1 SYNOPSIS

 use whatbot::Database::Table::Factoid;

=head1 DESCRIPTION

whatbot::Database::Table::Factoid provides database functionality for factoids.

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

=item whatbot::Database::Table

=over 4

=item whatbot::Database::Table::Factoid

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut