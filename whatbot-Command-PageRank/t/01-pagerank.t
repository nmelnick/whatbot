#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::Command::PageRank', 'Load module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

ok( my $pr = whatbot::Command::PageRank->new({
	'base_component' => $base_component,
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
