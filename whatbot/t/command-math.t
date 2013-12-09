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


#my $triggers = $trigger->triggers;
#is( ref($triggers), 'HASH', 'triggers are a hash' );
#
## Empty checking
#is( %$triggers, 0, 'triggers are empty' );
#is( $trigger->stats(), 'There are 0 triggers set.', 'stats shows empty/0/plural' );
#is(
#	$trigger->unset( $message, ['random'] ),
#	'I could not find that trigger.',
#	'unset without exists',
#);
#is(
#	@{ $trigger->find( $message, ['a'] ) },
#	0,
#	'find without exists is an empty arrayref',
#);
#is( $trigger->listener($message), undef, 'no items means listener returns nothing' );
#
## Regex
#my $response = $trigger->set( $message, [''] );
#like( $response, qr/Invalid trigger/, 'Empty set is invalid' );
#$response = $trigger->set( $message, ['foo bar'] );
#like( $response, qr/Invalid trigger/, 'No regex is invalid' );
#$response = $trigger->set( $message, ['/foo bar'] );
#like( $response, qr/Invalid trigger/, 'Half regex is invalid' );
#$response = $trigger->set( $message, ['foo/ bar'] );
#like( $response, qr/Invalid trigger/, 'Half regex is invalid' );
#$response = $trigger->set( $message, ['/f/oo/ bar'] );
#like( $response, qr/Invalid trigger/, 'Unescaped regex is invalid' );
#
#$response = $trigger->set( $message, ['/foo/ bar'] );
#is( $response, 'Trigger set.', '/foo/ is valid' );
#
#my $foo_message = $message->clone();
#$foo_message->content('foo');
#$response = $trigger->listener($foo_message);
#ok( $response, 'foo message has response' );
#is( ref($response), 'ARRAY', 'foo message response is arrayref' );
#is( @$response, 1, 'foo message response has one element' );
#is( $response->[0], 'bar', 'foo message response is bar' );
#
#$response = $trigger->set( $message, ['/foo/ baz'] );
#like( $response, qr/^A trigger already exists for/, 'second /foo/ is invalid' );
#
#is( keys %{$trigger->triggers}, 1, 'triggers have 1' );
#is( $trigger->stats(), 'There is 1 trigger set.', 'stats shows 1/singular' );
#is( @{ $trigger->find( $message, ['ba'] ) }, 1, 'find has 1 result' );
#
#$response = $trigger->set( $message, ['/fo/ baz'] );
#is( $response, 'Trigger set.', '/fo/ is valid' );
#
#$response = $trigger->listener($foo_message);
#ok( $response, 'foo message has response' );
#is( ref($response), 'ARRAY', 'foo message response is arrayref' );
#is( @$response, 2, 'foo message response has two elements' );
#like( $response->[1], qr/ba[rz]/, 'foo message response 1 is bar or baz' );
#like( $response->[0], qr/ba[rz]/, 'foo message response 2 is baz or bar' );
#
#is( keys %{$trigger->triggers}, 2, 'triggers have 2' );
#is( $trigger->stats(), 'There are 2 triggers set.', 'stats shows 2/plural' );
#is( @{ $trigger->find( $message, ['ba'] ) }, 2, 'find has 2 results' );
#
#is(
#	$trigger->unset( $message, ['/foo/'] ),
#	'Removed trigger.',
#	'unset foo works',
#);
#is(
#	$trigger->unset( $message, ['/fo/'] ),
#	'Removed trigger.',
#	'unset foo works',
#);
#
#is( keys %{$trigger->triggers}, 0, 'triggers are empty' );
#is( $trigger->stats(), 'There are 0 triggers set.', 'stats shows empty/0/plural' );
#is( @{ $trigger->find( $message, ['ba'] ) }, 0, 'find has 0 results' );
#
#clear_soup();
#
#$response = $trigger->set( $message, ['event:random foo'] );
#like( $response, qr/No idea what the/, 'random event is invalid' );
#$response = $trigger->set( $message, ['enter foo'] );
#like( $response, qr/Invalid trigger/, 'good event without event: is invalid' );
#$response = $trigger->set( $message, ['event:enter foo'] );
#is( $response, 'Trigger set.', 'enter is valid' );
#$response = $trigger->set( $message, ['event:leave foo'] );
#is( $response, 'Trigger set.', 'leave is valid' );
#$response = $trigger->set( $message, ['event:user_change foo'] );
#is( $response, 'Trigger set.', 'user_change is valid' );
#$response = $trigger->set( $message, ['event:enter(foo=bar) foo'] );
#like( $response, qr/Invalid trigger/, 'params as part of event is not valid' );
#$response = $trigger->set( $message, ['event:enter (foo=bar) foo'] );
#is( $response, 'Trigger set.', 'params in event is valid' );
#
#sub clear_soup {
#	$base_component->database->handle->do('delete from soup');
#	return;
#}

done_testing();

1;
