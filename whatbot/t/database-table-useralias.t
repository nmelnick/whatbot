#!/usr/bin/env perl

use Test::More;

use whatbot::Test;
use_ok( 'whatbot::Database::Table::UserAlias', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

my $url = whatbot::Database::Table::UserAlias->new( base_component => $base_component );
ok( $url, 'Object created' );

done_testing();
