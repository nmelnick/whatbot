###########################################################################
# whatbot/IO/Log.pm
###########################################################################
# whatbot logfile connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::IO::Log extends whatbot::IO {
	use whatbot::Progress;

	has 'file_handle'   => ( is => 'rw' );
	has 'line_count'    => ( is => 'rw' );
	has 'current_line'  => ( is => 'rw' );
	has 'progress'      => ( is => 'rw' );

	method BUILD {
		my $name = 'Log';
		$self->name($name);
		$self->me( $self->my_config->{'me'} );
	}

	method connect {
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

	method disconnect {
		$self->log->write( 'Closing ' . $self->my_config->{'filepath'} );
		close( $self->file_handle );
	}

	method event_loop {
		my $fh = $self->file_handle;
		$self->progress(
			whatbot::Progress->new( 
				'restrict_updates'  => 1000,
				'max'               => $self->line_count,
				'show_count'        => 1
			)
		) unless ( defined $self->progress );
	
		if ( my $line = <$fh> ) {
			$self->{'current_line'}++;
			$self->parse_line($line);
			$self->progress->update( $self->current_line );
		} else {
			$self->progress->finish;
			$self->parent->kill_self(1);
		}
	}

	# Send a message
	method send_message( $message ) {
	}


	method parse_line( $line ) {
	}
}

1;
