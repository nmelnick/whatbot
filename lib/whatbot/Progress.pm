###########################################################################
# whatbot/Progress.pm
###########################################################################
#
# progress bar for whatbot
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Progress;
use Moose;

has 'max' => (
	is			=> 'rw',
	isa 		=> 'Int'
);

has 'restrictUpdates' => (
	is	=> 'rw',
	isa	=> 'Int'
);

has 'showCount' => (
	is	=> 'rw',
	isa	=> 'Int'
);


sub update {
	my ($self, $current) = @_;
	
	return if ($self->restrictUpdates and $current % $self->restrictUpdates != 0);
	return unless ($self->max and $self->max > 0);

	my $pct = int(($current / $self->max) * 100);
	my $line = "[";
	for (my $c = 0; $c < int($pct * 0.7); $c++) {
		$line .= "=";
	}
	for (my $c = 0; $c < (65 - int($pct * 0.65)); $c++) {
		$line .= "-";
	}
	$line .= "] " . $pct . "% ";
	if ($self->showCount) {
		$line .= $current . "/" . $self->max;
	}
	for (my $c = 0; $c < (80 - length($line)); $c++) {
		$line .= " ";
	}
	$line .= "\r";
	print $line;
}

sub finish {
	my ($self) = @_;
	
	$self->restrictUpdates(0);
	$self->update($self->max);
	print "\n";
}

1;