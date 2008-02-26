###########################################################################
# whatbot/Command/BeerTime.pm
###########################################################################
# Called whenever it sees a time, with 'home' or 'beer' within the last 3 
# lines
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::BeerTime;
use Moose;
extends 'whatbot::Command';

has 'lineCache' => (
	is		=> 'ro',
	isa		=> 'HashRef',
	default	=> sub { {} }
);

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Extension");
	$self->listenFor("");
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	my $nick = $messageRef->from;
	
	my @insults = (
		"Fuck you, $nick.",
		"Go die in a fire, $nick.",
		"You suck, $nick."
	);
	
	# Always maintain a stack of 3
	if (defined $self->lineCache->{$nick}
		   and scalar(@{$self->lineCache->{$nick}}) == 3) {
			
		shift(@{$self->lineCache->{$nick}});
		
	}
	push(@{$self->lineCache->{$nick}}, $messageRef->content);
	
	if ($messageRef->content =~ /\d\d?\:\d\d/) {
		foreach my $msg (@{$self->lineCache->{$nick}}) {
			if ($msg =~ /\bbeer/i or $msg =~ /\bhome\b/i) {
				return $insults[rand @insults];
			}
		}
	}
	return undef;
}

1;
