###########################################################################
# whatbot/Database/Table/URL.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::Database::Table::URL extends whatbot::Database::Table {
    use Image::Size qw(imgsize);
    use URI;
    use WWW::Mechanize::GZip;
    use Mojo::DOM;

    has 'table_protocol' => ( is => 'rw', isa => 'whatbot::Database::Table' );
    has 'table_domain'   => ( is => 'rw', isa => 'whatbot::Database::Table' );
    has 'agent'          => ( is => 'ro', isa => 'Any', default => sub {
        my $mech = WWW::Mechanize::GZip->new( agent => 'whatbot/' . $whatbot::VERSION );
        $mech->timeout(5);
        $mech->add_header( 'Referer' => undef );
        $mech->stack_depth(0);
        return $mech;
    });

    method BUILD (...) {     
        $self->init_table({
            'name'        => 'url',
            'primary_key' => 'url_id',
            'defaults'    => {
                'timestamp' => { 'database' => 'now' }
            },
            'columns'     => {
                'url_id' => {
                    'type'  => 'serial'
                },
                'timestamp' => {
                    'type'  => 'integer'
                },
                'protocol_id' => {
                    'type'  => 'integer'
                },
                'domain_id' => {
                    'type'  => 'integer'
                },
                'path' => {
                    'type'  => 'varchar',
                    'size'  => 255
                },
                'user' => {
                    'type'  => 'varchar',
                    'size'  => 255
                },
                'title' => {
                    'type'  => 'varchar',
                    'size'  => 512
                }
            }
        });
        my $protocol = whatbot::Database::Table->new(
            'base_component' => $self->parent->base_component
        );
        $protocol->init_table({
            'name'        => 'url_protocol',
            'primary_key' => 'protocol_id',
            'indexed'     => ['name'],
            'columns'     => {
                'protocol_id' => {
                    'type'  => 'serial'
                },
                'name'    => {
                    'type'  => 'varchar',
                    'size'  => 12
                },
            }
        });
        $self->table_protocol($protocol);
        my $domain = whatbot::Database::Table->new(
            'base_component' => $self->parent->base_component
        );
        $domain->init_table({
            'name'        => 'url_domain',
            'primary_key' => 'domain_id',
            'indexed'     => ['name'],
            'defaults'    => {
                'timestamp' => { 'database' => 'now' }
            },
            'columns'     => {
                'domain_id' => {
                    'type'  => 'serial'
                },
                'timestamp' => {
                    'type'  => 'integer'
                },
                'name'    => {
                    'type'  => 'varchar',
                    'size'  => 255
                },
            }
        });
        $self->table_domain($domain);
    }

    method get_protocol ( Str $protocol ) {
        my $protocol_row = $self->table_protocol->search_one({
            'name' => $protocol
        });
        unless ($protocol_row) {
            $protocol_row = $self->table_protocol->create({
                'name' => $protocol
            });
        }

        return $protocol_row->protocol_id;
    }

    method get_domain ( Str $domain ) {
        my $domain_row = $self->table_domain->search_one({
            'name' => $domain
        });
        unless ($domain_row) {
            $domain_row = $self->table_domain->create({
                'name' => $domain
            });
        }

        return $domain_row->domain_id;
    }

    method url ( Str $url, Str $from? ) {
        my $uri = URI->new($url);
        my $protocol_id = $self->get_protocol( $uri->scheme );
        my $domain_id = $self->get_domain( $uri->host );

        # Check if exists
        my $row = $self->search_one({
            'protocol_id' => $protocol_id,
            'domain_id'   => $domain_id,
            'path'        => $uri->path,
        });
        unless ($row) {
            my $title = $self->retrieve_url($url);
            $row = $self->create({
                'user'        => $from,
                'title'       => $title,
                'domain_id'   => $domain_id,
                'protocol_id' => $protocol_id,
                'path'        => $uri->path . ( $uri->query ? '?' . $uri->query : '' )
            });
        }
    }

    method retrieve_url ($url) {
        my $title;
        my $response;
        eval {
            $response = $self->agent->get($url);
        };
        if ( ( not $@ ) and $response ) {
            if ( $self->agent->status < 400 ) {
                $title = 'No parsable title';
                if ( $url =~ /twitter\.com/ ) {
                  my $dom = Mojo::DOM->new($self->agent->content);
                  my $tweet_id = (split("/", $url))[-1];
                  my $tweet = $dom->at('[data-tweet-id="' . $tweet_id . '"]');

                  $title = '@' . $tweet->attr('data-screen-name') . ': ' . $tweet->at(".tweet-text")->all_text;

                } elsif ( $self->agent->title ) {
                  $title = $self->agent->title;

                } elsif ( $self->agent->ct =~ /^image/ ) {
                    my ( $width, $height, $type ) = imgsize(\$self->agent->content);
                    if ($type) {
                        $title = $type . ' Image: ' . $width . 'x' . $height;
                    }
                    
                }
            } elsif ( $self->show_failures() ) {
                my $status = $self->agent->status;
                if ( $status == 401 or $status == 403 ) {
                    $title = '! Authorization required';
                } elsif ( $status == 404 ) {
                    $title = '! Not Found';
                } else {
                    $title = '! Error ' . $self->agent->status;
                }
            }
        } else {
            $title = '! Unable to retrieve (' . $url . ' - ' . $self->agent->status . ' ' . $self->agent->content . ')';
        }
        return $title;
    }

    method show_failures() {
        my $config = $self->config->{'commands'}->{'url'};
        if ($config) {
            return if ( $config->{'hide_failures'} );
        }
        return 1;
    }
}

1;

=pod

=head1 NAME

whatbot::Database::Table::URL - Database model for url

=head1 SYNOPSIS

 use whatbot::Database::Table::URL;

=head1 DESCRIPTION

whatbot::Database::Table::URL does stuff.

=head1 METHODS

=over 4


=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Database::Table

=over 4

=item whatbot::Database::Table::URL

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
