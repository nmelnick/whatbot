#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Whatbot::Test;

unless ( $ENV{'WB_OPENWEATHERMAP_API_KEY'} ) {
    plan skip_all => 'Requires WB_OPENWEATHERMAP_API_KEY environment variable to run live tests.';
    done_testing();
}

require_ok( 'Whatbot::Command::Weather::Openweathermap' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $openweathermap = Whatbot::Command::Weather::Openweathermap->new({
    'api_key' => $ENV{'WB_OPENWEATHERMAP_API_KEY'},
}), 'new' );

my $object = $openweathermap->get_current('05455');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Fairfield', 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

$object = $openweathermap->get_current('seattle, us');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Seattle', 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

$object = $openweathermap->get_current('toronto, ca');
ok( $object, 'has a response' );
is( ref($object), 'Whatbot::Command::Weather::Current', 'correct object type' );
ok( $object->display_location, 'has display location' );
is( $object->display_location, 'Toronto', 'has correct display location' );
ok( defined $object->temperature_f, 'has temperature' );
ok( $object->to_string, 'to_string works' );

throws_ok(
    sub { $openweathermap->get_current('abcd') },
    qr/^Unwilling to figure out what you meant by "abc/,
    'get_current handles bad location'
);

$object = $openweathermap->get_forecast('05455');
ok( $object, 'has a response' );
is( ref($object), 'ARRAY', 'response is array' );
my $first = $object->[0];
is( ref($first), 'Whatbot::Command::Weather::Forecast', 'correct object type' );
ok( $first->weekday,'has weekday' );
ok( defined $first->high_temperature_f, 'has high temperature' );
ok( defined $first->low_temperature_f, 'has low temperature' );
ok( $first->to_string, 'to_string works' );

throws_ok(
    sub { $openweathermap->get_forecast('abcd') },
    qr/^Unwilling to figure out what you meant by "abc/,
    'get_forecast handles bad location'
);

done_testing();
