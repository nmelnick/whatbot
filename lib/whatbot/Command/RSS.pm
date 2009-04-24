###########################################################################
# whatbot/Command/RSS.pm
###########################################################################
# Monitor a RSS feed
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::RSS;
use Moose;
BEGIN { extends 'whatbot::Command' }

use Data::Dumper;
use Digest::MD5 'md5_hex';
use LWP::UserAgent ();
use XML::Simple;

has 'ua'         => ( is => 'ro', isa => 'LWP::UserAgent', default => sub {
    LWP::UserAgent->new( 'agent' => 'Mozilla/5.0', 'timeout' => 10 ); 
} );
has 'last_entry' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'last_check' => ( is => 'rw' );
has 'feeds'      => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	
	if ( $self->{'my_config'} ) {
	    if ( $self->my_config->{'feed'} ) {
	        my $feeds = $self->my_config->{'feed'};
	        $feeds = [ $feeds ] unless ( ref($feeds) eq 'ARRAY' );
	        
	        foreach my $feed (@$feeds) {
	            next unless ( $feed->{'io'} );
	            my $md5 = md5_hex( $feed->{'url'} );
	            $feed->{'md5'} = $md5;
    	        my $last_entry = $self->model('Soup')->get($md5);
    	        if ($last_entry) {
    	            $last_entry =~ s/^.*?\{/\{/;
    	            $self->last_entry->{$md5} = eval "$last_entry";
    	        }
    	        push( @{ $self->feeds }, $feed );
	        }
	        if ( scalar(@{ $self->feeds }) ) {
        	    $self->timer->enqueue( 10, \&retrieve_rss, $self );
	        } else {
    	        $self->log->write('RSS: Config found, but one or more feeds are missing a feed URL. Skipping.');
	        }
	    } else {
	        $self->log->write('RSS: Config found, but missing a feed. Skipping.');
	    }
	} else {
	    $self->log->write('RSS: No config found, skipping.');
	}
}

sub retrieve_rss : Command {
    my ( $self ) = @_;
    
    foreach my $feed (@{ $self->feeds }) {
        my $response = $self->ua->get( $feed->{'url'} );

        if ( $response->is_success ) {
            my $xml_doc;
            eval {
                $xml_doc = XMLin( $response->content );
            };
            if ($@) {
                $self->last_check({
                    'stamp'  => scalar( localtime(time) ),
                    'status' => 'Error parsing feed: ' . $@
                });
            } else {
                my $last_entry;
                my @items = reverse( @{ $xml_doc->{'channel'}->{'item'} } );
                if ( $self->last_entry->{ $feed->{'md5'} } and $self->last_entry->{ $feed->{'md5'} }->{'guid'} ) {
                    $last_entry = $self->last_entry->{ $feed->{'md5'} }->{'guid'};
                } else {
                    my $last_num = ( scalar(@items) > 1 ? scalar(@items) - 2 : scalar(@items) - 1 );
                    $last_entry = ( ref( $items[$last_num]->{'guid'} ) eq 'HASH' ? $items[$last_num]->{'guid'}->{'content'} : $items[$last_num]->{'guid'} );
                }
            
                my $seen_last;
                foreach my $item (@items) {
                    my $guid = ( ref( $item->{'guid'} ) eq 'HASH' ? $item->{'guid'}->{'content'} : $item->{'guid'} );
                    if ( $guid eq $last_entry ) {
                        $seen_last++;
                    } elsif ($seen_last) {
                        my $entry = {
                            'guid'  => $guid,
                            'text'  => ( $item->{'title'} or $item->{'description'} ),
                            'url'   => $item->{'link'}
                        };
                        if ( $feed->{'include'} ) {
                            my $include = $feed->{'include'};
                            next unless ( $entry->{'text'} =~ /$include/ );
                        }
                        if ( $feed->{'exclude'} ) {
                            my $exclude = $feed->{'exclude'};
                            next unless ( $entry->{'text'} =~ /$exclude/ );
                        }
                        $self->last_entry->{ $feed->{'md5'} } = $entry;
                        my $message = new whatbot::Message(
                            'to' => '',
                            'from' => '',
                            'content' => '[RSS] ' . $xml_doc->{'channel'}->{'title'} . ': ' . $entry->{'text'} . ' (' . $entry->{'url'} . ')',
                			'base_component'	=> $self->parent->base_component
                        );
                        $self->ios->{ $feed->{'io'} }->send_message($message);
                    
                        $Data::Dumper::Indent = 0;
                        $self->model('Soup')->set( $feed->{'md5'}, Data::Dumper::Dumper($entry) );
                        $self->last_check({
                            'stamp'  => scalar( localtime(time) ),
                            'status' => 'Successfully retrieved ' . scalar(@items) . ' from ' . $xml_doc->{'channel'}->{'title'}
                        });
                    }
                }
            }
        } else {
            $self->last_check({
                'stamp'  => scalar( localtime(time) ),
                'status' => 'Error retrieving feed: ' . $response->status_line
            });
        }
    }
	$self->timer->enqueue( ( $self->my_config->{'interval'} or 60 ), \&retrieve_rss, $self );
}

sub status : Command {
	my ( $self, $message ) = @_;
	
	return ( $self->last_check ? 'Last checked on ' . $self->last_check->{'stamp'} . ', status: ' . $self->last_check->{'status'} : undef );
}

sub last : Command {
	my ( $self, $message ) = @_;
	
}

sub help {
    return 'RSS monitors an RSS feed for new entries. You can retrieve the last entry using "rss last", and get the status of the monitor with "rss status".';
}

1;