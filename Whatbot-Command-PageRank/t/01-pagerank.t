#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::Command::PageRank', 'Load module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $pr = Whatbot::Command::PageRank->new({
	'my_config'      => {},
	'name'           => 'PageRank',
}), 'new' );

$pr->register();

ok( $pr->help(), 'has help' );

my %expected = (
	'www.google.com'   => 9,
	'www.facebook.com' => 9,
	'www.ask-cow.com'  => 'not found'
);

foreach my $site ( keys %expected ) {
	is(
		$pr->parse_message( {}, [ '', $site ] ),
		'The PageRank for "http://' . $site . '" is ' . $expected{$site} . '.',
		'correct rank for ' . $site
	);
}

done_testing();

1;
