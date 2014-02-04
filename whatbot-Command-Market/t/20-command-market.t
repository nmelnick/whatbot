#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::Command::Market', 'Load Module' );

my $test = whatbot::Test->new();
$test->initialize_state();

ok( my $market = whatbot::Command::Market->new({
	'my_config'      => {},
	'name'           => 'Market',
}), 'new' );

$market->register();

# Known good
foreach my $stock ( qw( AAPL MSFT GOOG CSCO DRIV ) ) {
	my $response = $market->parse_message( 'market ' . $stock, [$stock] );
	ok( $response, $stock . ' has response' );
	ok( $response =~ /$stock/, $stock . ' contains ticker' );
	ok( $response =~ /\d+\.\d+/, $stock . ' contains price' );
}

# Known weird
foreach my $stock ( '^DJI DRIV' ) {
	my $sanitized = $stock;
	$sanitized =~ s/\^/\\^/g;
	my $response = $market->parse_message( 'market ' . $stock, [$stock] );
	ok( $response, $stock . ' has response' );
	ok( $response =~ /$sanitized/, $stock . ' contains ticker' );
	ok( $response =~ /\d+\.\d+/, $stock . ' contains price' );
}

done_testing();
