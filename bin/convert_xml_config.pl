#!/usr/bin/perl
#
# Convert XML config file to JSON. Accepts a file path, outputs to STDOUT.
# Recommendation:
#   cp conf/whatbot.conf conf/whatbot.conf.bak
#   bin/convert_xml_config.pl conf/whatbot.conf.bak > conf/whatbot.conf
#
use strict;
use warnings;
use XML::Simple;
use JSON::XS;

my ( $config_file ) = @ARGV;
unless ($config_file) {
	die 'Requires path to config file.';
}

my $config = eval {
	return XMLin( $config_file, KeyAttr => [] );
};
if ($@) {
	die 'ERROR: Error in config file "' . $config_file . '"! Parser reported: ' . $@;
}

my $json = JSON::XS->new()->pretty(1);
print $json->encode($config);

1;
