#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::Command::Math', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();
$test->initialize_models($base_component);

ok( my $math = whatbot::Command::Math->new({
	'base_component' => $base_component,
	'my_config'      => {},
	'name'           => 'Math',
}), 'new' );

$math->register();

my $message = whatbot::Message->new({ from => 'Test', to => 'context', content => '' });

is( $math->_parse('1+1'), '2');
# Format number only result
is( $math->_parse('100*100'), '10,000'); 
# Leave non-number only alone
is( $math->_parse('1e50*1e50'), '1e+100');

is( $math->rand($message, ["1"]), "Test: 1");

ok( $math->rand($message, ["1 2 3"]), /Test: [123]{1}/ );

done_testing();

1;
