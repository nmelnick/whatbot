#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;

use_ok( 'whatbot::Helper::Bootstrap', 'Load Module' );

is( @whatbot::Helper::Bootstrap::applications, 0, 'no applications' );

ok( whatbot::Helper::Bootstrap->add_application( 'Test application', '/' ), 'add application' );

is( @whatbot::Helper::Bootstrap::applications, 1, '1 application' );

ok( ! whatbot::Helper::Bootstrap->add_application( 'Test application', '/' ), 'add same application' );

is( @whatbot::Helper::Bootstrap::applications, 1, '1 application' );


done_testing();
