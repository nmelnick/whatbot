###########################################################################
# Google.pm
# Pulls the first result or the first image from Google.
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Google;
use Moose;
BEGIN { extends 'Whatbot::Command' }

use LWP::UserAgent ();
use URI::Escape qw(uri_escape uri_unescape);
use HTML::Entities qw(decode_entities);
use HTML::Strip ();
use JSON::XS qw(decode_json encode_json);
use Encode;
use utf8;
use namespace::autoclean;

has 'ua' => (
	is      => 'ro',
	isa     => 'LWP::UserAgent',
	default => sub { LWP::UserAgent->new; }
);

has 'stripper' => (
	is      => 'ro',
	isa     => 'HTML::Strip',
	default => sub { HTML::Strip->new( emit_spaces => 0, decode_entities => 1 ); }
);

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	$self->ua->agent('Mozilla/5.0');
}

sub search : Command {
	my ( $self, $message, $captures ) = @_;

	my $query = join( ' ', @$captures );
	my $content = $self->_search($query);
	unless ($content) {
		return 'I could not get a response from Google.';
	}
	return $content;
}

sub image : Command {
	my ( $self, $message, $captures ) = @_;

	my $query = join( ' ', @$captures );
	my $content = $self->_image_search($query);
	unless ($content) {
		return 'I could not get a response from Google.';
	}
	return $content;
}

sub _search {
	my ( $self, $query ) = @_;

	my $url = sprintf( 'http://www.google.com/search?q=%s', uri_escape($query) );
	my $response = $self->ua->get($url);
	if ( $response->is_success ) {
		my @results = ( $response->decoded_content =~ /(<h3 class="r"><a href="\/url\?q=http[^"]+">.+?<\/a>.*?<span class="st">.+?<\/span>)/g );
		if ( @results and $results[0] =~ /<a href="\/url\?q=(http[^"]+)">(.+?)<\/a>.*?<span class="st">(.+?)<\/span/ ) {
			my ( $url, $title, $description ) = ( decode_entities($1), decode_entities($2), decode_entities($3) );
			my $octets = encode_utf8($title);
			utf8::downgrade($octets);
			$title = $self->stripper->parse($octets);
			$self->stripper->eof;
			$title = decode_utf8($title);
			$octets = encode_utf8($description);
			utf8::downgrade($octets);
			$description = $self->stripper->parse($octets);
			$self->stripper->eof;
			$description = decode_utf8($description);
			$description =~ s/\d+ (hours|days|minutes) ago //;
			return [
				sprintf( "%s - %s", $title, $description ),
				$url,
			];
		}
	}
	return;
}

sub _image_search {
	my ( $self, $query ) = @_;

	my $url = 'https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=' . uri_escape($query);
	my $response = $self->ua->get($url);
	if ( $response->is_success ) {
		my $doc = decode_json( $response->decoded_content() );
		if ($doc) {
			return $doc->{responseData}->{results}->[0]->{unescapedUrl};
		}
	}

	return;
}

__PACKAGE__->meta->make_immutable();

1;

