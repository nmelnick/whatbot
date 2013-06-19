###########################################################################
# whatbot/Command/PageRank.pm
###########################################################################
# Gathers the google pagerank for a given site
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::PageRank;
use Moose;
BEGIN { extends 'whatbot::Command' }

use WWW::Google::PageRank;
use namespace::autoclean;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub parse_message : CommandRegEx('(for)? (.*)[\?\s]?') {
	my ( $self, $message, $captures ) = @_;
	
	if ($captures) {
		my $pr = WWW::Google::PageRank->new();
		my $site = $captures->[1];
		unless ($site =~ /^https?:\/\//) {
			$site = "http://" . $site;
		}
		return 'The PageRank for "' . $site . '" is ' . ( $pr->get($site) or 'not found' ) . '.';
	}
}

sub help {
    return 'PageRank provides the Google PageRank for a given site. Use by entering "pagerank www.example.com".';
}

__PACKAGE__->meta->make_immutable;

1;