###########################################################################
# Whatbot/Command/PageRank.pm
###########################################################################
# Gathers the google pagerank for a given site
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::PageRank;
use Moose;
BEGIN { extends 'Whatbot::Command' }

use WWW::Google::PageRank;
use namespace::autoclean;

our $VERSION = '0.1';

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub parse_message : CommandRegEx('(for )?(.*)[\?\s]?') {
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

=pod

=head1 NAME

Whatbot::Command::PageRank - Retrieve the given web site's Google PageRank

=head1 DESCRIPTION

Whatbot::Command::Market provides the chat user a Google PageRank for the site
they provide.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
