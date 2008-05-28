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
	
	my %candidates = (
	    'jameth'        => '',
	    'legomymalfoy'  => '',
	    'rm'            => '',
	);
	my %candidates_percentages;
	my $response = $self->agent->get('http://www.livejournal.com/poll/?id=1192389');
    if ($response->is_success and $self->agent->success) {
    	foreach my $who_cares (keys %candidates) {
    	    if ($self->agent->content =~ m{<p>$who_cares<br /><span style='white-space: nowrap'><img src=.*?width='7' alt='' /> <b>(\d+)</b> \(([\d\.]+)%\)</span>}) {
    	        warn join(' ', $who_cares, $1, $2);
    	        $candidates{$who_cares} = $1;
    	        $candidates_percentages{$who_cares} = $2;
    	    }
    	}
    	my @ordered;
    	foreach my $who_cares (sort { $candidates{$b} cmp $candidates{$a} } keys %candidates) {
    	    push(@ordered, $who_cares . ': ' . $candidates{$who_cares} . ' votes, ' . $candidates_percentages{$who_cares} . '%');
	    }
	    return join(' | ', @ordered);
	} else {
	    return "Something's fucked with the poll URL.";
	}
	return undef;
}

1;