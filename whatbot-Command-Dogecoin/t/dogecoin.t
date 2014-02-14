#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::Command::Dogecoin', 'Load Module' );

my $test = whatbot::Test->new();
$test->initialize_state();

ok( my $dogecoin = whatbot::Command::Dogecoin->new({
	'my_config'      => {},
	'name'           => 'Dogecoin',
}), 'new' );

$dogecoin->register();

done_testing();

1;
