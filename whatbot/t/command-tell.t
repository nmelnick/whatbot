#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::Command::Tell', 'Load Module' );

my $test = whatbot::Test->new();
$test->initialize_state();
$test->initialize_models();

ok( my $tell = whatbot::Command::Tell->new({
	'my_config'      => {},
	'name'           => 'Tell',
}), 'new' );

$tell->register();

my $message = whatbot::Message->new({ from => 'Test', to => 'context', content => '' });

request_tell();
query_tell();
do_tell();

sub request_tell {
	is(
		$tell->request_tell( $message, [ 'Foo Bar' ] ),
		'OK, Test.',
		'Send <Test> tell Foo Bar'
	);
	is(
		$tell->request_tell( $message, [ 'Foo Bar' ] ),
		'You are already telling that to Foo, Test.',
		'Repeat <Test> tell Foo Bar'
	);
}

sub query_tell {
	my $response = $tell->query_tell( $message, ['Foo'] );
	is(
		ref($response),
		'ARRAY',
		'query_tell returns arrayref',
	);
	is(
		@$response,
		1,
		'query_tell has one answer',
	);
	is(
		$response->[0],
		'Telling: Test wants Foo to know "Bar."',
		'query_tell answer',
	);
}

sub do_tell {
	is(
		$tell->do_tell( 'IO:context', { 'nick' => 'Nope' } ),
		undef,
		'do_tell to no trigger results in nothing',
	);
	is(
		$tell->do_tell( 'IO:context', { 'nick' => 'Foo' } )->[0],
		'Foo, Test wants you to know Bar.',
		'do_tell to trigger results in one response',
	);
}

done_testing();

1;
