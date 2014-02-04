#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::IO::AIM', 'Load module' );

my $test = whatbot::Test->new();
$test->initialize_state();

eval {
	my $aim = whatbot::IO::AIM->new({
		'my_config'      => {},
	});
};
like( $@, qr/AIM component requires a/, 'Error when missing screenname and password' );

eval {
	my $aim = whatbot::IO::AIM->new({
		'my_config'      => {
			'screenname' => 'foo',
		},
	});
};
like( $@, qr/AIM component requires a/, 'Error when missing password' );

eval {
	my $aim = whatbot::IO::AIM->new({
		'my_config'      => {
			'password' => 'foo',
		},
	});
};
like( $@, qr/AIM component requires a/, 'Error when missing screenname' );

done_testing();

1;
