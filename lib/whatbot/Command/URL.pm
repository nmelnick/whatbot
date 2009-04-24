###########################################################################
# whatbot/Command/URL.pm
###########################################################################
# keeps track of URLs, URL information, and history
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::URL;
use Moose;
BEGIN { extends 'whatbot::Command'; }

use Image::Size qw(imgsize);
use POSIX qw(strftime);
use URI;
use WWW::Mechanize;

has 'version' => ( is => 'ro', isa => 'Int', default => 1 );
has 'agent' => ( is => 'ro', isa => 'Any', default =>
    sub {
        my $mech = new WWW::Mechanize;
        $mech->timeout(5);
        $mech->add_header( 'Referer' => undef );
        $mech->stack_depth(0);
        return $mech;
    }
);

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
    
    $self->get_database();
}

sub store_url : GlobalRegEx('.*?((https|http|ftp|news|feed|telnet):\/\/[^\s]+).*') {
    my ( $self, $message, $captures ) = @_;
    
    my $url = $captures->[0];
    my $uri = new URI($url);
    
    # Get/Set Protocol
    my ($protocol) = @{ $self->store->retrieve(
        'url_protocol',
        [qw/protocol_id/],
        { name => $uri->scheme }
    ) };
    unless ( defined $protocol and defined $protocol->{'protocol_id'} ) {
        $self->store->store(
            'url_protocol',
            {
                'name'    => $uri->scheme
            }
        );
        ($protocol) = @{ $self->store->retrieve(
            'url_protocol',
            [qw/protocol_id/],
            { 'name' => $uri->scheme }
        ) };
    }
    
    # Get/Set Domain
    my ($domain) = @{ $self->store->retrieve(
        'url_domain',
        [qw/domain_id/],
        { 'name' => $uri->host }
    ) };
    unless ( defined $domain and defined $domain->{'domain_id'} ) {
        $self->store->store(
            'url_domain',
            {
                'name'        => $uri->host,
                'timestamp'   => time
            }
        );
        ($domain) = @{ $self->store->retrieve(
            'url_domain',
            [qw/domain_id/],
            { 'name' => $uri->host }
        ) };
    }
    
    # Get/Set URL
    my ($db_url) = @{ $self->store->retrieve(
        'url',
        [qw/url_id user title/],
        {
            'domain_id'   => $domain->{'domain_id'},
            'protocol_id' => $protocol->{'protocol_id'},
            'path'        => $uri->path
        }
    ) };
    unless ( defined $db_url and defined $db_url->{'url_id'} ) {
        my $title = 'No parsable title';
        my $response;
        eval {
            $response = $self->agent->get($url);
        };
        if ( !$@ and $response->is_success and $self->agent->success ) {
            if ( $self->agent->status < 400 ) {
                if ( $self->agent->title() ) {
                    $title = $self->agent->title();
                    
                } elsif ( $self->agent->ct =~ /^image/ ) {
                    my ($width, $height, $type) = imgsize(\$self->agent->content);
                    if ($type) {
                        $title = $type . ' Image: ' . $width . 'x' . $height;
                    }
                    
                }
            } else {
                $title = '! Error ' . $self->agent->status;
            }
        } else {
            $title = '! Unable to retrieve';
        }
        $self->store->store(
            'url',
            {
                'timestamp'   => time,
                'user'        => $message->from(),
                'title'       => $title,
                'domain_id'   => $domain->{'domain_id'},
                'protocol_id' => $protocol->{'protocol_id'},
                'path'        => $uri->path . ($uri->query ? '&' . $uri->query : '')
            }
        );
        ($db_url) = @{ $self->store->retrieve(
            'url',
            [qw/url_id user title/],
            {
                'domain_id'   => $domain->{'domain_id'},
                'protocol_id' => $protocol->{'protocol_id'},
                'path'        => $uri->path . ($uri->query ? '&' . $uri->query : '')
            }
        ) };
    }
    
    if ( defined $db_url and defined $db_url->{'title'} ) {
        return '[URL: ' . $db_url->{'title'} . ']';
    }
}

sub last : Command {
    my ( $self, $message ) = @_;
    
    my ($db_url) = @{ $self->store->retrieve(
        'url',
        [qw/url_id user title timestamp domain_id protocol_id path/],
        undef,
        'url_id DESC',
        1
    ) };
    if ( defined $db_url ) {
        my ($url_domain) = @{ $self->store->retrieve(
            'url_domain',
            [qw/name/],
            {
                'domain_id' => $db_url->{'domain_id'}
            }
        ) };
        my ($url_protocol) = @{ $self->store->retrieve(
            'url_protocol',
            [qw/name/],
            {
                'protocol_id' => $db_url->{'protocol_id'}
            }
        ) };
    
        return [
            '[URL: ' . $url_protocol->{'name'} . '://' . $url_domain->{'name'} . '/' . $db_url->{'path'} . ' ]',
            '(From ' . $db_url->{'user'} . ' on ' . strftime( '%Y-%m-%d at %H:%m', localtime( $db_url->{'timestamp'} ) ) . ' - "' . $db_url->{'title'} . '")'
        ];
    }
}

sub search : Command {
    my ( $self, $message, $captures ) = @_;
    
}

sub help {
    my ( $self ) = @_;
    
    return [
        'URL is a URL management module for whatbot. All canonical URLs seen ' .
        'in any open channels or chats are stored with the title of the found ' .
        'page, user information, and timestamp. To query URLs, start the ' .
        'command with "url" and then one of the following: ',
        ' * "last" to show the last URL given, along with the user, title and time.'
    ];
}

sub get_database {
    my ($self) = @_;
    
    my $version;
    eval {
	    ($version) = @{ $self->store->retrieve('url_info', [qw/version/], { }) };
	};
	if ( $@ or !defined $version ) {
	    warn 'Supporting database tables for URL not found. Creating.';
	    $self->create_database();
	    ($version) = @{ $self->store->retrieve('url_info', [qw/version/], { }) };
	}
	if ( $version->{'version'} < $self->version() ) {
	    warn 'Database version ' . $version->{'version'} . ' is less than module version ' . $self->version() . '.';
	    $self->update_database( $version->{'version'} );
	}
}

sub create_database {
    my ($self) = @_;
    
    $self->store->handle->do(q{
       CREATE TABLE url_info (
         version   INTEGER PRIMARY KEY,
         timestamp INTEGER
       ); 
    });
    $self->store->store('url_info', {
        'version' => '1',
        'timestamp' => time
    });
    $self->store->handle->do(q{
       CREATE TABLE url_protocol (
         protocol_id INTEGER PRIMARY KEY,
         name        VARCHAR (12)
       );
    });
    $self->store->store('url_protocol', { 'name' => 'http' });
    $self->store->store('url_protocol', { 'name' => 'https' });
    $self->store->store('url_protocol', { 'name' => 'ftp' });
    $self->store->store('url_protocol', { 'name' => 'telnet' });
    $self->store->store('url_protocol', { 'name' => 'news' });
    $self->store->handle->do(q{
       CREATE TABLE url_domain (
         domain_id INTEGER PRIMARY KEY,
         timestamp INTEGER,
         name      VARCHAR (255)
       ); 
    });
    $self->store->handle->do(q{
       CREATE TABLE url (
         url_id       INTEGER PRIMARY KEY,
         timestamp    INTEGER,
         protocol_id  INTEGER,
         domain_id    INTEGER,
         path         VARCHAR (255),
         user         VARCHAR (255),
         title        VARCHAR (512)
       ); 
    });
}

1;