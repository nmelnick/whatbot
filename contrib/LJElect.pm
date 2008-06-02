###########################################################################
# whatbot/Command/LJElect.pm
###########################################################################
# Tracks the LJ Election.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::LJElect;
use Moose;
extends 'whatbot::Command';
use WWW::Mechanize;

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
	$self->listenFor(qr/^lj election/);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	my %candidates;
	my %candidates_percentages;
	my $response = $self->agent->get('http://www.livejournal.com/poll/?id=1192389');
    if ($response->is_success and $self->agent->success) {
        my @candidate_matches = ($self->agent->content =~/<p>(\w+)<br \/><span style='white-space: nowrap'><img src='http:\/\/p-stat.livejournal.com\/img\/poll\/leftbar.gif' style='vertical-align:middle' height='14' alt='' \/><img src='http:\/\/p-stat.livejournal.com\/img\/poll\/mainbar.gif' style='vertical-align:middle' height='14' width='\d+' alt='' \/><img src='http:\/\/p-stat.livejournal.com\/img\/poll\/rightbar.gif' style='vertical-align:middle' height='14' width='7' alt='' \/> <b>(\d+)<\/b> \(([\d\.]+)%\)<\/span><\/p>/gc);
    	for (my $i = 0; $i < scalar(@candidate_matches); $i += 3) {
    	    my ($who, $votes, $pct) = ($candidate_matches[$i], $candidate_matches[$i + 1], $candidate_matches[$i + 2]);
    	    last if (defined $candidates{$who});
	        $candidates{$who} = $votes;
	        $candidates_percentages{$who} = $pct;
    	}
    	my @ordered;
    	foreach my $who_cares (sort { $candidates{$b} <=> $candidates{$a} } keys %candidates) {
    	    push(@ordered, $who_cares . ': ' . $candidates{$who_cares} . ' votes, ' . $candidates_percentages{$who_cares} . '%');
	    }
	    return join(' | ', @ordered[0..4]);
	} else {
	    return "Something's fucked with the poll URL.";
	}
	return undef;
}

1;