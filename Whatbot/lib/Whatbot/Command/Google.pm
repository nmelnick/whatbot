###########################################################################
# Google.pm
# Pulls the first result or the first image from Google.
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Google;
use Moose;
use Whatbot::Command;
BEGIN { extends 'Whatbot::Command' }

use LWP::UserAgent ();
use URI::Escape qw(uri_escape uri_unescape);
use HTML::Entities qw(decode_entities);
use JSON::XS qw(decode_json encode_json);
use Whatbot::Utility;
use Encode;
use namespace::autoclean;

has 'ua' => (
	is      => 'ro',
	isa     => 'LWP::UserAgent',
	default => sub { LWP::UserAgent->new; }
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

sub _search {
	my ( $self, $query ) = @_;

	my $url = sprintf( 'http://www.google.com/search?q=%s', uri_escape($query) );
	my $response = $self->ua->get($url);
	if ( $response->is_success ) {
		my @results = ( $response->decoded_content =~ /(<h3 class="r"><a href="\/url\?q=http[^"]+">.+?<\/a>.*?<span class="st">.+?<\/span>)/sg );
		if ( @results and $results[0] =~ /<a href="\/url\?q=(http[^"]+)">(.+?)<\/a>.*?<span class="st">(.+?)<\/span/s ) {
			my ( $url, $title, $description ) = ( decode_entities($1), decode_entities($2), decode_entities($3) );
			$title = Whatbot::Utility::html_strip($title);
			$description = Whatbot::Utility::html_strip($description);
			$description =~ s/\d+ (hours|days|minutes) ago //;
			return [
				sprintf( "%s - %s", $title, $description ),
				$url,
			];
		}
	}
	return;
}

__PACKAGE__->meta->make_immutable();

1;

