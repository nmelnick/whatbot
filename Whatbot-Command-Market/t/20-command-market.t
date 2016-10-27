#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Market', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $market = Whatbot::Command::Market->new({
	'my_config'      => {},
	'name'           => 'Market',
}), 'new' );

$market->register();

my $response = $market->get_data( 'IBM' );
ok( exists $response->{'range_52week'}, 'data contains 52wk range' );
ok( exists $response->{'vol_and_avg'}, 'data contains vol and avg' );
ok( exists $response->{'pe_ratio'}, 'data contains P/E' );

foreach my $stock ( qw( MS ) ) {
	my $response = $market->detail( 'stockrep ' . $stock, [$stock] );
	ok( $response, $stock . ' stockrep has response' );
	ok( $response =~ /$stock/, $stock . ' stockrep contains ticker' );
}

# Known good
foreach my $stock ( qw( AAPL MSFT GOOG CSCO ) ) {
	my $response = $market->parse_message( 'market ' . $stock, [$stock] );
	ok( $response, $stock . ' has response' );
	ok( $response =~ /$stock/, $stock . ' contains ticker' );
	ok( $response =~ /\d+\.\d+/, $stock . ' contains price' );
}

foreach my $query ( "AAPL,MSFT" ) {
	my $response = $market->parse_message( 'market ' . $query, [$query] );
	ok( $response, $query . ' has response' );
        ok( ref($response) eq 'ARRAY', "response is array" );
        ok( @$response == 2, "response has 2 parts" );
}
# Known weird
foreach my $stock ( '^DJI' ) {
	my $sanitized = $stock;
	$sanitized =~ s/\^/\\^/g;
	my $response = $market->parse_message( 'market ' . $stock, [$stock] );
	ok( $response, $stock . ' has response' );

        # ^DJI is aka .DJI
	ok( $response =~ /$sanitized/, $stock . ' contains ticker' ) unless $stock eq '^DJI';

	ok( $response =~ /\d+\.\d+/, $stock . ' contains price' );
}

done_testing();
