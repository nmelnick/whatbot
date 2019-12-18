#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Weather::Current', 'Load Module' );

my $current = Whatbot::Command::Weather::Current->new();
my $f = $current->to_celsius(80);
is( substr( $f, 0, 5 ), '26.66', 'F to C converts properly' );

my $temp_string = $current->temp_string('80');
is( $temp_string, '80 F (26.67 C)', 'temp_string converts properly' );

done_testing();
