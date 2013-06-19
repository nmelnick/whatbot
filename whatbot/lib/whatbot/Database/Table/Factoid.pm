###########################################################################
# whatbot/Database/Table/Factoid.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::Database::Table::Factoid extends whatbot::Database::Table {
    use Digest::SHA1 qw(sha1_hex);

    has 'table_description' => ( is => 'rw', isa => 'whatbot::Database::Table' );
    has 'table_ignore'      => ( is => 'rw', isa => 'whatbot::Database::Table' );

    method BUILD ($) {       
        $self->init_table({
            'name'        => 'factoid',
            'primary_key' => 'factoid_id',
            'indexed'     => ['subject'],
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

        my $description = whatbot::Database::Table->new(
            'base_component' => $self->parent->base_component
        );
        $description->init_table({
            'name'        => 'factoid_description',
            'primary_key' => 'hash',
            'indexed'     => [ 'user', 'factoid_id' ],
            'defaults'    => {
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
        my $ignore = whatbot::Database::Table->new(
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
        
        $self->table_description($description);
        $self->table_ignore($ignore);
    }

    method is_silent ($subject) {
        $subject = lc($subject);
        
        my $factoid = $self->search_one({
            'subject' => $subject
        });
        if ($factoid) {
            return $factoid->silent;
        }
        
        return;
    }

    method toggle_silence ($subject) {
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

    method factoid ( $subject, $is?, $from?, $plural? ) {
        my $original = $subject;
        $subject = lc($subject);
    
        # Get existing factoid info, if available
        my $factoid = $self->search_one({
            'subject' => $subject
        });
        return if ( !$factoid and !$is );
    
        # Assign fact info if defined
        if ($is) {
        
            # Nuke all factoids if user says no
            if ($subject =~ /no, /i) {
                $subject =~ s/no, //i;
                $self->forget($subject);
            }
        
            unless ($factoid) {
                # Check if ignore
                return if ( $self->ignore($subject) );
            
                # Check if plural
                my $is_plural = $plural;
            
                $self->create({
                    'is_or'     => 0,
                    'is_plural' => $is_plural,
                    'created'   => time,
                    'updated'   => time,
                    'subject'   => $subject
                });
                $factoid = $self->search_one({
                    'subject' => $subject
                });
            }
        
            # Remove also, because we don't care
            my $also = $is =~ s/^also //;
        
            # Nuke <reply> if not or and more than one fact
            if ( $is =~ /^<reply>/ ) {
                my $factoid_count = $self->count({
                    'factoid_id' => $factoid->factoid_id
                });
                return unless ( $factoid_count == 0 or ( $factoid->is_or and $factoid->is_or == 1 ) );
            }
        
            # Nuke response if we already have a reply
            my $first_fact = $self->table_description->search_one({
                'factoid_id' => $factoid->factoid_id
            });
            return if ( $first_fact and $first_fact->description =~ /^<reply>/ );
            
            # Don't bother if this exact factoid combo exists
            return if (
                $factoid
                and $self->table_description->count({
                    'factoid_id' => $factoid->factoid_id,
                    'hash'       => sha1_hex( Encode::encode_utf8($is) )
                })
            );
        
            # Handle or (||)
            if ( $is =~ /\|\|/ ) {
                $factoid->is_or(1);
                $factoid->save();
                foreach my $fact ( split( / \|\| /, $is ) ) {
                    $self->table_description->create({
                        'factoid_id'  => $factoid->factoid_id,
                        'description' => $fact,
                        'hash'        => sha1_hex( Encode::encode_utf8($fact) ),
                        'user'        => $from,
                        'updated'     => time
                    });
                }
            } else {
                $self->table_description->create({
                    'factoid_id'  => $factoid->factoid_id,
                    'description' => $is,
                    'hash'        => sha1_hex( Encode::encode_utf8($is) ),
                    'user'        => $from,
                    'updated'     => time
                });
            }
        }
    
        # Retrieve factoid description
        my $facts = $self->table_description->search({
            'factoid_id' => $factoid->factoid_id
        });
    
        # If facts are given, return hashref of factoid data and facts
        if (@$facts) {
            if (scalar(@$facts) == 1) {
                return {
                    'user'    => $facts->[0]->user,
                    'factoid' => $factoid,
                    'facts'   => [ $facts->[0]->description ],
                };
            } else {
                return {
                    'factoid' => $factoid,
                    'facts'   => [ map { $_->description } @$facts ]
                };
            }
        }
    
        return;
    }

    method forget ( Str $subject ) {
        $subject = lc($subject);
    
        my $factoid = $self->search_one({
            'subject' => $subject
        });
        return unless ($factoid);
    
        my $facts = $self->table_description->search({
            factoid_id => $factoid->factoid_id
        });
        foreach my $fact (@$facts) {
            $fact->delete();
        }
        $factoid->delete();
    
        return 1;
    }

    method ignore ( Str $subject, $store? ) {
        $subject = lc($subject);
    
        my $ignore = $self->table_ignore->search_one({
            'subject' => $subject
        });
        if ( $store and !$ignore ) {
            $self->table_ignore->create({
                'subject' => $subject,
            });
            $ignore = $self->table_ignore->search_one({
                'subject' => $subject
            });
        }
    
        return $ignore;
    }

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

=item table_description

=item table_ignore

=back

=head1 METHODS

=over 4

=item is_silent()

=item toggle_silence()

=item factoid()

=item forget($subject)

=item ignore($subject)

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
