#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Weather', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $weather = Whatbot::Command::Weather->new({
  'my_config'      => {},
  'name'           => 'Weather',
}), 'new' );

$weather->register();

done_testing();
