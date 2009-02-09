###########################################################################
# whatbot/Log.pm
###########################################################################
# log handler for whatbot
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Log;
use Moose;

use POSIX qw(strftime);

has 'log_directory' => ( is	=> 'rw', isa => 'Str', required => 1 );

sub BUILD {
	my ( $self, $log_dir ) = @_;
	
	binmode( STDOUT, ':utf8' );
	unless ( -e $self->log_directory ) {
	    if ( $self->log_directory and length( $self->log_directory ) > 3 ) {
	        my $result = mkdir( $self->log_directory );
	        $self->write('Created directory "' . $self->log_directory . '".') if ($result);
	    }
	    die 'ERROR: Cannot find log directory "' . $self->log_directory . '", could not create.';
	}
	
	$self->write('whatbot::Log loaded successfully.');
}

sub error {
    my ( $self, $entry ) = @_;
    
    $self->write( '*ERROR: ' . $entry );
}

sub write {
	my ( $self, $entry ) = @_;
	
	my $output = '[' . strftime( '%Y-%m-%d %H:%M:%S', localtime(time) ) . '] ' . $entry . "\n";
	print $output;
    open( LOG, '>>' . $self->log_directory . '/whatbot.log' )
        or die 'Cannot open logfile for writing: ' . $!;
    binmode( LOG, ':utf8' );
    print LOG $output;
    close(LOG);
}

1;