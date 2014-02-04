#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::Command::Weather', 'Load Module' );

my $test = whatbot::Test->new();
$test->initialize_state();

ok( my $weather = whatbot::Command::Weather->new({
	'my_config'      => {},
	'name'           => 'Weather',
}), 'new' );

$weather->register();

done_testing();
