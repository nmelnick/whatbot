#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use whatbot::Test;

use_ok( 'whatbot::Database::Table::Karma', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

my $karma = whatbot::Database::Table::Karma->new( base_component => $base_component );
ok( $karma, 'Object created' );

is( $karma->count(), 0, 'table has zero records' );
is( $karma->get('example'), undef, 'example has no karma' );

throws_ok(
	sub { $karma->increment('example') },
	qr/missing required argument/,
	'increment without from throws exception'
);

ok( $karma->increment( 'example', 'test' ), 'example increment ok' );
is( $karma->count(), 1, 'table has one record' );
is( $karma->get('example'), 1, 'example has karma of 1' );

throws_ok(
	sub { $karma->decrement('example') },
	qr/missing required argument/,
	'decrement without from throws exception'
);

ok( $karma->decrement( 'example', 'test' ), 'example decrement ok' );
is( $karma->count(), 2, 'table has two records' );
is( $karma->get('example'), 0, 'example has karma of 0' );

is_deeply(
	$karma->get_extended('example'),
	{
		'Increments' => 1,
		'Decrements' => 1,
		'Last'       => [ 'test', '-1' ],
	},
	'example get_extended matches',
);

done_testing();
