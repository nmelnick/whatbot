#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Whatbot::Test;

require_ok( 'Whatbot::Command::Weather::Openmeteo' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $weather = Whatbot::Command::Weather::Openmeteo->new({}), 'new' );

my $object = $weather->get_current('43.653,-79.387');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
like( $object->display_location, qr/Toronto, Ontario, Canada/, 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

$object = $weather->get_current('fairfield, vt');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Fairfield, Vermont, United States', 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

$object = $weather->get_current('toronto, ca');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
like( $object->display_location, qr/Toronto, Ontario, Canada/, 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

$object = $weather->get_current('mallacoota, australia');
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Mallacoota, Victoria, Australia', 'has correct display location when provided a town instead of a city' );

$object = $weather->get_forecast('43.653,-79.387');
ok( $object, 'has a response' );
is( ref($object), 'ARRAY', 'response is array' );
my $first = $object->[0];
is( ref($first), 'Whatbot::Command::Weather::Forecast', 'correct object type' );
ok( $first->weekday, 'has weekday' );
ok( $first->weekday =~ /day$/, 'weekday is a name' );
ok( defined $first->high_temperature_f, 'has high temperature' );
ok( defined $first->low_temperature_f, 'has low temperature' );
ok( $first->to_string, 'to_string works' );

done_testing();
