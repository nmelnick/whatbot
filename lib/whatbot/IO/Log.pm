###########################################################################
# whatbot/IO/Log.pm
###########################################################################
# whatbot logfile connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::IO::Log;
use Moose;
extends 'whatbot::IO';

use whatbot::Progress;

has 'file_handle'   => ( is => 'rw' );
has 'line_count'    => ( is => 'rw' );
has 'current_line'  => ( is => 'rw' );
has 'progress'      => ( is => 'rw' );

sub BUILD {
	my ( $self ) = @_;
	
	my $name = 'Log';
	$self->name($name);
	$self->me( $self->my_config->{'me'} );
}

sub connect {
	my ( $self ) = @_;
	
	# Open log file, store scalar file_handle
	$self->log->write( 'Opening ' . $self->my_config->{'filepath'} );
	my $fh;
	open ( $fh, $self->my_config->{'filepath'} );
	$self->file_handle($fh);
	
	# Get File Count
	my $lines = 0;
	my $buffer;
    open( FILE, $self->my_config->{'filepath'} ) or die "Can't open: $!";
    while ( sysread FILE, $buffer, 4096 ) {
        $lines += ( $buffer =~ tr/\n// );
    }
    close (FILE);
	$self->line_count($lines);
}

sub disconnect {
	my ( $self ) = @_;
	
	$self->log->write( 'Closing ' . $self->my_config->{'filepath'} );
	close( $self->file_handle );
}

sub event_loop {
	my ( $self ) = @_;
	
	my $fh = $self->file_handle;
	$self->progress(
		new whatbot::Progress( 
			'restrict_updates'  => 1000,
			'max'               => $self->line_count,
			'show_count'        => 1
		)
	) unless ( defined $self->progress );
	
	if ( my $line = <$fh> ) {
		$self->{'current_line'}++;
		$self->parseLine($line);
		$self->progress->update( $self->current_line );
	} else {
		$self->progress->finish;
		$self->parent->kill_self(1);
	}
}

# Send a message
sub send_message {
	my ( $self, $message ) = @_;
	
}


sub parse_line {
	my ( $self, $line ) = @_;
}

1;