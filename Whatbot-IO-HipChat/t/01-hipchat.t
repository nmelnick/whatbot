#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::IO::HipChat', 'Load module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

eval {
	my $aim = Whatbot::IO::HipChat->new({
		'my_config'      => {},
	});
};
like( $@, qr/HipChat component requires a/, 'Error when missing username and password' );

eval {
	my $aim = Whatbot::IO::HipChat->new({
		'my_config'      => {
			'username' => '1234_4312',
		},
	});
};
like( $@, qr/HipChat component requires a/, 'Error when missing password' );

eval {
	my $aim = Whatbot::IO::HipChat->new({
		'my_config'      => {
			'password' => 'foo',
		},
	});
};
like( $@, qr/HipChat component requires a/, 'Error when missing username' );

done_testing();

1;
