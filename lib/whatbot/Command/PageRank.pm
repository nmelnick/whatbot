###########################################################################
# whatbot/Command/PageRank.pm
###########################################################################
# Gathers the google pagerank for a given site
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::PageRank;
use Moose;
extends 'whatbot::Command';
use WWW::Google::PageRank;

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Extension");
	$self->listenFor(qr/^pagerank( for)? (.*)[\?\s]?/i);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	if ($messageRef->content =~ $self->listenFor) {
		my $pr = new WWW::Google::PageRank;
		my $site = $2;
		unless ($site =~ /^https?:\/\//) {
			$site = "http://" . $site;
		}
		return "The PageRank for '$site' is " . ($pr->get($site) or "not found") . ".";
	}
}

1;