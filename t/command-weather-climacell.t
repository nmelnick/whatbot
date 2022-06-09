#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Whatbot::Test;

unless ( $ENV{'WB_CLIMACELL_API_KEY'} ) {
    plan skip_all => 'Requires WB_CLIMACELL_API_KEY environment variable to run live tests.';
    done_testing();
}

use_ok( 'Whatbot::Command::Weather::Climacell', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $climacell = Whatbot::Command::Weather::Climacell->new({
    'api_key' => $ENV{'WB_CLIMACELL_API_KEY'},
}), 'new' );

my $object = $climacell->get_current('43.653,-79.387');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Old Toronto, Ontario, Canada', 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

$object = $climacell->get_current('fairfield, vt');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Fairfield, Vermont, United States of America', 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

$object = $climacell->get_current('toronto, ca');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Toronto, Ontario, Canada', 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

$object = $climacell->get_current('mallacoota, australia');
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Mallacoota, Victoria, Australia', 'has correct display location when provided a town instead of a city' );

throws_ok(
    sub { $climacell->get_current('abcd') },
    qr/^Unwilling to figure out what you meant by /,
    'get_current handles bad location'
);

$object = $climacell->get_forecast('43.653,-79.387');
ok( $object, 'has a response' );
is( ref($object), 'ARRAY', 'response is array' );
my $first = $object->[0];
is( ref($first), 'Whatbot::Command::Weather::Forecast', 'correct object type' );
ok( $first->weekday, 'has weekday' );
ok( $first->weekday =~ /day$/, 'weekday is a name' );
ok( defined $first->high_temperature_f, 'has high temperature' );
ok( defined $first->low_temperature_f, 'has low temperature' );
ok( $first->to_string, 'to_string works' );

throws_ok(
    sub { $climacell->get_forecast('abcd') },
    qr/^Unwilling to figure out what you meant by /,
    'get_forecast handles bad location'
);

done_testing();
