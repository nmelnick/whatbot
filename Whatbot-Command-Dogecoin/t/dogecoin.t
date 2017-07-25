#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Dogecoin', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $dogecoin = Whatbot::Command::Dogecoin->new({
	'my_config'      => {},
	'name'           => 'Dogecoin',
}), 'new' );

$dogecoin->register();

ok( $dogecoin->parse_message( 'dogecoin', [] ) );

done_testing();

1;
