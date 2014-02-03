###########################################################################
# Log.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Log - Provides logging from within whatbot

=head1 SYNOPSIS

 extends 'whatbot::Component';
 
 $self->log->write('This is a message.');
 $self->log->error('This is an error!');

=head1 DESCRIPTION

whatbot::Log provides basic log functionality from within whatbot. whatbot
loads this class during startup, and is available under the 'log' accessor
in any module subclassed from whatbot::Component and loaded properly,
including Commands.

=head1 ATTRIBUTES

=over 4

=item last_error(bool)

Stores the last error written.

=item log_enabled(bool)

Defaults to 1/true. If set to false, log entries will not be written.

=back

=head1 METHODS

=over 4

=cut

class whatbot::Log {
    use POSIX qw(strftime);

    has 'log_directory' => ( is	=> 'rw', isa => 'Maybe[Str]' );
    has 'last_error'    => ( is	=> 'rw', isa => 'Str' );
    has 'name'          => ( is => 'rw', isa => 'Maybe[Str]' );
    has 'fh'            => ( is => 'rw' );
    has 'log_enabled'   => ( is => 'rw', isa => 'Bool', default => 1 );

    method BUILD ( $log_dir ) {
    	binmode( STDOUT, ':utf8' );
        $self->fh(*STDOUT);
    	unless ( not $self->log_directory or -e $self->log_directory ) {
    	    if ( $self->log_directory and length( $self->log_directory ) > 3 ) {
    	        my $result = mkdir( $self->log_directory );
    	        $self->write('Created directory "' . $self->log_directory . '".') if ($result);
    	    }
    	    $self->write( 'ERROR: Cannot find log directory "' . $self->log_directory . '", could not create.' );
            $self->log_directory(undef);
    	}
	
        return;
    }

=item error( $line )

Writes message to standard out / log file and 'warn's to STDERR.

=cut

    method error ( Str $entry ) {
        $self->last_error($entry);
        $self->write( '*ERROR: ' . $entry );
        warn $entry;
    }

=item write( $line )

Writes message to standard out / log file.

=cut

    method write ( Str $entry ) {
        return unless ( $self->log_enabled );
        my $fh = $self->fh;
        if ( $self->name ) {
            $entry = sprintf( '[%s] ', $self->name ) . $entry;
            $self->name(undef);
        }

    	my $output = '[' . strftime( '%Y-%m-%d %H:%M:%S', localtime(time) ) . '] ' . $entry . "\n";
    	print $fh $output;
        if ( $self->log_directory ) {
            open( LOG, '>>' . $self->log_directory . '/whatbot.log' )
                or die 'Cannot open logfile for writing: ' . $!;
            binmode( LOG, ':utf8' );
            print LOG $output;
            close(LOG);
        }
    }
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut