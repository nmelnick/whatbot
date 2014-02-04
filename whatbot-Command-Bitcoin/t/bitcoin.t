#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use whatbot::Test;
use JSON ();

use_ok( 'whatbot::Command::Bitcoin', 'Load Module' );

my $test = whatbot::Test->new();
$test->initialize_state();

ok( my $bitcoin = whatbot::Command::Bitcoin->new({
	'my_config'      => {},
	'name'           => 'Bitcoin',
}), 'new' );

$bitcoin->register();

my $pricing = '{"markets":{"bitstamp":{"price":"1.029e+03","vol":"5.429e+04"},"btce":{"price":"1.002e+03","vol":"5.852e+04"}},"slot":null}';
my $pricing_object = JSON::from_json($pricing);
my $expected = ( ( 1029 * 54290 ) + ( 1002 * 58520 ) ) / ( 54290 + 58520 );
is( $bitcoin->_average_pricing($pricing_object), sprintf( '%0.02f', $expected ) );

done_testing();

1;
