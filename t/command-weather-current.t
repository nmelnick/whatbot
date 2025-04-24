#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Whatbot::Test;

require_ok( 'Whatbot::Command::Weather::Current' );

my $current = Whatbot::Command::Weather::Current->new();
my $f = $current->to_celsius(80);
is( substr( $f, 0, 5 ), '26.66', 'F to C converts properly' );

my $temp_string = $current->temp_string('80');
is( $temp_string, '80 F (26.67 C)', 'temp_string converts properly' );

$current->add_alert('The sky is falling');
$current->add_alert('The sky is falling');
ok( scalar(@{$current->unique_alerts}) == 1, 'unique_alerts deduplicates' );

done_testing();
