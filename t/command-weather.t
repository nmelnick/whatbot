#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

require_ok( 'Whatbot::Command::Weather' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $weather = Whatbot::Command::Weather->new({
  'my_config'      => {},
  'name'           => 'Weather',
}), 'new' );

$weather->register();

done_testing();
