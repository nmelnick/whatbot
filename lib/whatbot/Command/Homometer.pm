###########################################################################
# whatbot/Command/Homometer.pm
###########################################################################
# Private #what extensions
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Homometer;
use Moose;
extends 'whatbot::Command';

has 'lineCache' => (
	is		=> 'ro',
	isa		=> 'ArrayRef',
	default	=> sub { [] }
);

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Core");
	$self->listenFor("");
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	# Check if we need to output homometer
	if ($messageRef->content =~ /^homometer/i) {
		return $self->getHomometer();
	} else {
        	# Always maintain a stack of 50
    		if (defined $self->lineCache and scalar(@{$self->lineCache}) == 30) {
                	shift(@{$self->lineCache});
        	}
	        push(@{$self->lineCache}, $messageRef->from . "|||" . $messageRef->content);
	}
	
	return undef;
}

sub getHomometer {
	my ($self) = @_;
	
	my %scale = (
		'moo'		=> 20,
		'gay'		=> 15,
		'homo'		=> 15,
		'jameth'	=> 15,
		'buttsex'	=> 15,
		'canada'	=> 10,
		'blow me'	=> 10,
		'penis'		=> 10,
		'cock'		=> 10,
		'dong'		=> 10,
		'sparkle'	=> 10,
		'pony'		=> 10,
		'goatse'	=> 10,
		'europe'	=> 10,
		'e-date'	=> 10,
		wang	=> 10,
		cock	=> 10,
		balls	=> 10,
		scrotum	=> 10,
		sack	=> 10,
		testicles	=> 10,
		nuts	=> 10,
		teabag	=> 10,
		ass	=> 10,
		butt	=> 10,
		anus	=> 10,
		asshole	=> 10,
		bunghole	=> 10,
		assrape	=> 10,
		buttrape	=> 10,
		buttsex	=> 10,
		manberries	=> 10,
		starfish	=> 10,
		browneye	=> 10,
		"cinnamon ring"	=> 10,
		semen	=> 10,
		sperm	=> 10,
		jizz	=> 10,
		cum	=> 10,
		ejaculat	=> 10,
		manjuice	=> 10,
		suck	=> 10,
		fuck	=> 10,
		lick	=> 10,
		fondle	=> 10,
		cornhole	=> 10,
		'apple'		=> 8,
		'shit'		=> 8,
		'pd'		=> 8,
		'breasts'	=> 5,
		'oz'		=> 5
	);
	
	my $totalPoints = 0;
	foreach my $val (values %scale) {
		$totalPoints += $val;
	}
	my $maxScore = $totalPoints * 0.85;
	
	my $score = 0;
	foreach my $line (@{$self->lineCache}) {
		my ($who, $content) = split(/\|\|\|/, $line);
		foreach my $searchTerm (keys %scale) {
			my $assignedPoints = $scale{$searchTerm};
			if ($who =~ /sam/) {
				$assignedPoints *= 1.15;
			}
			if ($content =~ /$searchTerm/i) {
				$score += int($assignedPoints);
			}
		}
		if ($content =~ /pd/ and $who =~ /sam/i) {
			$score += 8;
		}
	}
	if ($score > 0) {
		return "The channel has a homometer of " . int(100*($score / $maxScore)) . "%";
	}
	
	return undef;
}

1;
