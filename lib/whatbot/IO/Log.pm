###########################################################################
# whatbot/IO/Log.pm
###########################################################################
#
# whatbot logfile connector
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::IO::Log;
use Moose;
extends 'whatbot::IO';
use whatbot::Progress;

has 'fileHandle' => (
	is	=> 'rw'
);

has 'lineCount' => (
	is	=> 'rw'
);

has 'currentLine' => (
	is	=> 'rw'
);

has 'Progress' => (
	is	=> 'rw'
);

sub BUILD {
	my ($self) = @_;
	
	my $name = "Log";
	$self->name($name);
	$self->me($self->my_config->{me});
}

sub connect {
	my ($self) = @_;
	
	# Open log file, store scalar filehandle
	$self->log->write("Opening " . $self->my_config->{filepath});
	my $fh;
	open ($fh, $self->my_config->{filepath});
	$self->fileHandle($fh);
	
	# Get File Count
	my $lines = 0;
	my $buffer;
    open(FILE, $self->my_config->{filepath}) or die "Can't open: $!";
    while (sysread FILE, $buffer, 4096) {
        $lines += ($buffer =~ tr/\n//);
    }
    close (FILE);
	$self->lineCount($lines);
}

sub disconnect {
	my ($self) = @_;
	
	$self->log->write("Closing " . $self->my_config->{filepath});
	close($self->fileHandle);
}

sub event_loop {
	my ($self) = @_;
	
	my $fh = $self->fileHandle;
	$self->Progress(
		new whatbot::Progress( 
			restrictUpdates => 1000,
			max 			=> $self->lineCount,
			showCount 		=> 1 )
	) unless (defined $self->Progress);
	
	if (my $line = <$fh>) {
		$self->{currentLine}++;
		$self->parseLine($line);
		$self->Progress->update($self->currentLine);
	} else {
		$self->Progress->finish;
		$self->parent->killSelf(1);
	}
}

# Send a message
sub sendMessage {
	my ($self, $messageObj) = @_;
	
}


sub parseLine {
	my ($self, $line);
}

1;