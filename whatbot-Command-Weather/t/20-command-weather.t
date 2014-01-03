#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::Command::Weather', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

ok( my $weather = whatbot::Command::Weather->new({
	'base_component' => $base_component,
	'my_config'      => {},
	'name'           => 'Weather',
}), 'new' );

$weather->register();

done_testing();
