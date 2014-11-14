#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;
use JSON ();

use_ok( 'Whatbot::Command::Bitcoin', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $bitcoin = Whatbot::Command::Bitcoin->new({
	'my_config'      => {},
	'name'           => 'Bitcoin',
}), 'new' );

$bitcoin->register();

my $pricing = '{"btc":{"usd":{"bitfinex":{"last":594.3,"volume":1537383.1},"bitstamp":{"last":592.41,"volume":984693.28},"btce":{"last":586.101,"volume":1532807.6},"localbitcoins":{"last":777.82947,"volume":181936.35}}},"other":{"slot":1401580800,"ver":"river"}}';
my $pricing_object = JSON::from_json($pricing);
is( $bitcoin->_average_pricing($pricing_object), 598.78, 'average matches' );

done_testing();

1;
