###########################################################################
# whatbot/Log.pm
###########################################################################
#
# log handler for whatbot
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Log;
use Moose;
use POSIX qw(strftime);

has 'logDirectory' => (
	is			=> 'rw',
	isa 		=> 'Str',
	required	=> 1
);


sub BUILD {
	my ($self, $logDir) = @_;
	
	die "ERROR: Cannot find log directory '" . $self->logDirectory . "'" unless (-e $self->logDirectory);
	$self->write("whatbot::Log loaded successfully.");
}

sub write {
	my ($self, $entry) = @_;
	
	my $output = "[" . strftime("%Y-%m-%d %H:%M:%S", localtime(time)) . "] " . $entry . "\n";
	print $output;
	# open(LOG, ">>" . $self->logDirectory . "/whatbot.log")
	# 	or die "Can't open logfile for writing: " . $!;
	# print LOG $output;
	# close(LOG);
}

1;