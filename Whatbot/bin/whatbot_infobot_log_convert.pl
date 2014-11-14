#!/usr/bin/perl
###########################################################################
# whatbot_infobot_log_convert.pl
###########################################################################
#
# parses an infobot module through the controller
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

$|++;
use strict;
use warnings;
use Cwd qw(realpath);
use Getopt::Long;

our $VERSION = "0.9.2";

# Get basedir
my $basedir = realpath($0);
my $appname = $0;
$appname =~ s/.*?\///g;
$basedir =~ s/\/$appname$//;
$basedir =~ s/\/bin$//;

# Check command line options
my $logFile = shift(@ARGV);
if (!$logFile or !-e $logFile) {
	die "Need valid log file to import.";
}
my $me = shift(@ARGV);
if (!$me) {
	die "Need username of bot to successfully import.";
}

my $configPath = $basedir . "/conf/whatbot.conf";
my $daemon = 0;
my $help;
GetOptions(
	'config=s'	=> \$configPath,
	'daemon' 	=> \$daemon,
	'help' 		=> \$help
);
usage() if ($help);
unless ($configPath and -e $configPath) {
	my @tryConfig = (
		$basedir . "/conf/whatbot.conf",
		"/etc/whatbot/whatbot.conf",
		"/etc/whatbot.conf",
		"/usr/local/etc/whatbot/whatbot.conf",
		"/usr/local/etc/whatbot.conf"
	);
	foreach (@tryConfig) {
		$configPath = $_ if (-e $_);
	}
	unless ($configPath and -e $configPath) {
		print "ERROR: Configuration file not found.\n";
		usage();
	}
}

# Initial requirements check
eval { require 5.008_001; };
if ($@) {
	print "ERROR: whatbot requires perl 5.8 or higher.";
	exit(-1);
}

print "whatbot " . $VERSION . "\n";
print "Running in interactive mode.\n";

# Start application
# Import whatbot
push(@INC, "$basedir/lib") if (-e "$basedir/lib");
require Whatbot;
my $whatbot = Whatbot->new( skip_extensions => 1 );
$whatbot->run($configPath, {
	interface	=> 'Log::Infobot',
	filepath	=> $logFile,
	me			=> $me,
	silent		=> 1
});

sub usage {
	print qq!whatbot_infobot_log_convert.pl $VERSION:

 -c --config  Path to configuration file (default: conf/Whatbot.conf)
 -h --help	  Print this help screen\n\n!;
	exit(0);
}

1;


