#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Whatbot::Test;

unless ( $ENV{'WB_WUNDERGROUND_API_KEY'} ) {
	plan skip_all => 'Requires WB_WUNDERGROUND_API_KEY environment variable to run live tests.';
	done_testing();
}

use_ok( 'Whatbot::Command::Weather::Wunderground', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $wunderground = Whatbot::Command::Weather::Wunderground->new({
	'api_key' => $ENV{'WB_WUNDERGROUND_API_KEY'},
}), 'new' );

my $object = $wunderground->get_current('05455');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
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
	sub { $wunderground->get_current('abcd') },
	qr/^Unwilling to figure out what you meant by\: abc/,
	'get_current handles bad location'
);

$object = $wunderground->get_forecast('05455');
ok( $object, 'has a response' );
is( ref($object), 'ARRAY', 'response is array' );
my $first = $object->[0];
is( ref($first), 'Whatbot::Command::Weather::Forecast', 'correct object type' );
ok( $first->weekday,'has weekday' );
ok( defined $first->high_temperature_f, 'has high temperature' );
ok( defined $first->low_temperature_f, 'has low temperature' );
ok( $first->to_string, 'to_string works' );

throws_ok(
	sub { $wunderground->get_forecast('abcd') },
	qr/^Unwilling to figure out what you meant by\: abc/,
	'get_forecast handles bad location'
);

done_testing();
