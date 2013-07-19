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

my $tempString = $weather->tempString('80');
ok( $tempString eq '80 F (26.67 C)', 'converts properly');

if($weather->api_key) {
  my $response = $weather->weather('weather 05455', ['05455']);
  ok( $response, 'has a response');
  ok( $response =~  /\d+[\.\d]* F \(\d+[\.\d]* C\)/, 'has both temperatures');
}

done_testing();
