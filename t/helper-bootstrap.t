#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;

require_ok( 'Whatbot::Helper::Bootstrap' );

is( @Whatbot::Helper::Bootstrap::applications, 0, 'no applications' );

ok( Whatbot::Helper::Bootstrap->add_application( 'Test application', '/' ), 'add application' );

is( @Whatbot::Helper::Bootstrap::applications, 1, '1 application' );

ok( ! Whatbot::Helper::Bootstrap->add_application( 'Test application', '/' ), 'add same application' );

is( @Whatbot::Helper::Bootstrap::applications, 1, '1 application' );


done_testing();
