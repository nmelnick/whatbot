#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use whatbot::Test;

use_ok( 'whatbot::Database::Table::Soup', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

my $soup = whatbot::Database::Table::Soup->new( base_component => $base_component );
ok( $soup, 'Object created' );

is( $soup->count(), 0, 'table has zero records' );

throws_ok(
	sub { $soup->get() },
	qr/missing required/,
	'get requires one param'
);

is( $soup->get('example'), undef, 'example is empty' );

throws_ok(
	sub { $soup->set('example') },
	qr/missing required/,
	'set requires one param'
);

ok( $soup->set( 'example', 'bar' ), 'set example to bar' );
is( $soup->count(), 1, 'table has one record' );
is( $soup->get('example'), 'bar', 'example is bar' );

is_deeply(
	$soup->get_hashref(),
	{
		'example' => 'bar',
	},
	'get_hashref matches get',
);

throws_ok(
	sub { $soup->clear() },
	qr/missing required/,
	'clear requires one param'
);

$soup->clear('example');
is( $soup->count(), 0, 'table has zero records' );
is( $soup->get('example'), undef, 'example is empty' );

done_testing();
