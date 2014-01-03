#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use whatbot::Test;

use_ok( 'whatbot::Command::Weather::Wunderground', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

unless ( $ENV{'WB_WUNDERGROUND_API_KEY'} ) {
	plan skip_all => 'Requires WB_WUNDERGROUND_API_KEY environment variable to run live tests.';
}

ok( my $wunderground = whatbot::Command::Weather::Wunderground->new({
	'api_key' => $ENV{'WB_WUNDERGROUND_API_KEY'},
}), 'new' );

my $object = $wunderground->get_current('05455');
ok( $object, 'has a response' );
is( ref($object), 'whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Fairfield, VT', 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( defined $object->feels_like_f, 'has feels like' );
ok( $object->to_string, 'to_string works' );

my $f = $object->to_celsius(80);
is( substr( $f, 0, 5 ), '26.66', 'F to C converts properly' );

my $temp_string = $object->temp_string('80');
is( $temp_string, '80 F (26.67 C)', 'temp_string converts properly' );

throws_ok(
	sub { $wunderground->get_current('abc') },
	qr/^Unwilling to figure out what you meant by\: abc/,
	'get_current handles bad location'
);

$object = $wunderground->get_forecast('05455');
ok( $object, 'has a response' );
is( ref($object), 'ARRAY', 'response is array' );
my $first = $object->[0];
is( ref($first), 'whatbot::Command::Weather::Forecast', 'correct object type' );
ok( $first->weekday,'has weekday' );
ok( defined $first->high_temperature_f, 'has high temperature' );
ok( defined $first->low_temperature_f, 'has low temperature' );
ok( $first->to_string, 'to_string works' );

throws_ok(
	sub { $wunderground->get_forecast('abc') },
	qr/^Unwilling to figure out what you meant by\: abc/,
	'get_forecast handles bad location'
);

done_testing();
