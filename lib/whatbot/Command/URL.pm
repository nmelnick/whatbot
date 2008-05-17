###########################################################################
# whatbot/Command/URL.pm
###########################################################################
# keeps track of URLs, URL information, and history
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::URL;
use Moose;
extends 'whatbot::Command';
use WWW::Mechanize;
use URI;

has 'version' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1
);

has 'agent' => (
    is      => 'ro',
    isa     => 'Any',
    default => sub {
        my $ua = new WWW::Mechanize;
        $ua->timeout(5);
        return $ua;
    }
);

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Extension");
	$self->listenFor([
	    '(https|http|ftp|news|feed|telnet)://',
	    '^url (search|who)'
	]);
	$self->requireDirect(0);
    
    $self->getDatabase();
}

sub parseMessage {
	my ($self, $messageRef) = @_;
    
    if ($messageRef->content =~ $self->listenFor->[0]) {
        return $self->storeUrl($messageRef);
    } elsif ($messageRef->content =~ $self->listenFor->[1]) {
        return $self->searchUrl($1);
    }
	
	return undef;
}

sub storeUrl {
    my ($self, $messageRef) = @_;
    
    my $url = $messageRef->content;
    $url =~ s/.*?((https|http|ftp|news|feed|telnet):\/\/[^\s]+).*/$1/;
    my $uri = new URI($url);
    
    # Get/Set Protocol
    my ($protocol) = @{ $self->store->retrieve(
        "url_protocol",
        [qw/protocol_id/],
        { name => $uri->scheme }
    ) };
    unless (defined $protocol and defined $protocol->{protocol_id}) {
        $self->store->store(
            "url_protocol",
            {
                name    => $uri->scheme
            }
        );
        ($protocol) = @{ $self->store->retrieve(
            "url_protocol",
            [qw/protocol_id/],
            { name => $uri->scheme }
        ) };
    }
    
    # Get/Set Domain
    my ($domain) = @{ $self->store->retrieve(
        "url_domain",
        [qw/domain_id/],
        { name => $uri->host }
    ) };
    unless (defined $domain and defined $domain->{domain_id}) {
        $self->store->store(
            "url_domain",
            {
                name        => $uri->host,
                timestamp   => time
            }
        );
        ($domain) = @{ $self->store->retrieve(
            "url_domain",
            [qw/domain_id/],
            { name => $uri->host }
        ) };
    }
    
    # Get/Set URL
    my ($db_url) = @{ $self->store->retrieve(
        "url",
        [qw/url_id user title/],
        {
            domain_id   => $domain->{domain_id},
            protocol_id => $protocol->{protocol_id},
            path        => $uri->path
        }
    ) };
    unless (defined $db_url and defined $db_url->{url_id}) {
        my $title;
        my $response = $self->agent->get($url);
        if ($response->is_success) {
            $title = $self->agent->title();
        } else {
            $title = "! Unable to retrieve";
        }
        $self->store->store(
            "url",
            {
                timestamp   => time,
                user        => $messageRef->from,
                title       => $title,
                domain_id   => $domain->{domain_id},
                protocol_id => $protocol->{protocol_id},
                path        => $uri->path
            }
        );
        ($db_url) = @{ $self->store->retrieve(
            "url",
            [qw/url_id user title/],
            {
                domain_id   => $domain->{domain_id},
                protocol_id => $protocol->{protocol_id},
                path        => $uri->path
            }
        ) };
    }
    
    if (defined $db_url and defined $db_url->{title}) {
        return '[URL: ' . $db_url->{title} . ']';
    }
}

sub searchUrl {
    my ($self, $urlFragment) = @_;
    
}

sub help {
    my ($self) = @_;
    
    return 
        'URL is a URL management module for whatbot. All canonical URLs seen ' .
        'in any open channels or chats are stored with the title of the found ' .
        'page, user information, and timestamp. To query URLs, start the ' .
        'command with "url" and then one of the following: ' .
        ' * "search" to start a query. Entering text after this point will ' .
        'search an entire URL and take longer. Limit the search by adding ' .
        '"domain" will limit the search to the domain name, "path" for the ' .
        'path.' .
        ' * "who" after a returned result will tell you who entered that URL, ' .
        'along with the timestamp.';
}

sub getDatabase {
    my ($self) = @_;
    
    my $version;
    eval {
	    ($version) = @{ $self->store->retrieve("url_info", [qw/version/], { }) };
	};
	if ($@ or !defined $version) {
	    warn 'Supporting database tables for URL not found. Creating.';
	    $self->createDatabase();
	    ($version) = @{ $self->store->retrieve("url_info", [qw/version/], { }) };
	}
	if ($version->{version} < $self->version()) {
	    warn 'Database version ' . $version->{version} . ' is less than module version ' . $self->version() . '.';
	    $self->updateDatabase($version->{version});
	}
}

sub createDatabase {
    my ($self) = @_;
    
    $self->store->handle->do(q{
       CREATE TABLE url_info (
         version   INTEGER PRIMARY KEY,
         timestamp INTEGER
       ); 
    });
    $self->store->store('url_info', { version => '1', timestamp => time });
    $self->store->handle->do(q{
       CREATE TABLE url_protocol (
         protocol_id INTEGER PRIMARY KEY,
         name        VARCHAR (12)
       );
    });
    $self->store->store('url_protocol', { name => 'http' });
    $self->store->store('url_protocol', { name => 'https' });
    $self->store->store('url_protocol', { name => 'ftp' });
    $self->store->store('url_protocol', { name => 'telnet' });
    $self->store->store('url_protocol', { name => 'news' });
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