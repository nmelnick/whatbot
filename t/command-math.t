#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Math', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();
$test->initialize_models();

ok( my $math = Whatbot::Command::Math->new({
	'my_config'      => {},
	'name'           => 'Math',
}), 'new' );

$math->register();

my $message = Whatbot::Message->new({ from => 'Test', to => 'context', content => '' });

is( $math->_parse('1+1'), '2');
# Format number only result
is( $math->_parse('100*100'), '10,000'); 
# Leave non-number only alone
is( $math->_parse('1e50*1e50'), '1e+100');

is( $math->rand($message, ["1"]), "Test: 1");

like( $math->rand($message, ["1 2 3"]), qr/Test: [123]{1}/, "picks a valid value" );

like( $math->roll($message, ["6"]), qr/Test: [123456]{1}/, "uses a valid number");
is( $math->roll($message, ["1"]), "Test: 1");

done_testing();

1;
