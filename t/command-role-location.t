#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Role::Location', 'Load Module' );

my $coordinate_location = Whatbot::Command::Role::Location->convert_location("43.653,-79.387");
ok( $coordinate_location, 'coordinate has a response' );
ok( $coordinate_location->{'coordinates'}, 'coordinate has coordinates' );
ok( $coordinate_location->{'display'}, 'coordinate has display' );
is( $coordinate_location->{'display'}, 'Old Toronto, Ontario, Canada', 'coordinate has correct display location' );

my $vt_location = Whatbot::Command::Role::Location->convert_location("fairfield, vt");
ok( $vt_location, 'vt has a response' );
ok( $vt_location->{'coordinates'}, 'vt has coordinates' );
ok( $vt_location->{'display'}, 'vt has display' );
is( $vt_location->{'display'}, 'Fairfield, Vermont, United States', 'vt has correct display location' );

my $toronto_location = Whatbot::Command::Role::Location->convert_location("toronto, ca");
ok( $toronto_location, 'toronto has a response' );
ok( $toronto_location->{'coordinates'}, 'toronto has coordinates' );
ok( $toronto_location->{'display'}, 'toronto has display' );
is( $toronto_location->{'display'}, 'Old Toronto, Ontario, Canada', 'toronto has correct display location' );

my $mallacoota_location = Whatbot::Command::Role::Location->convert_location("mallacoota, australia");
ok( $mallacoota_location, 'toronto has a response' );
is( $mallacoota_location->{'display'}, 'Mallacoota, Victoria, Australia', 'has correct display location when provided a town instead of a city' );

done_testing();
