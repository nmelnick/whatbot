#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::IO::AIM', 'Load module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

eval {
	my $aim = whatbot::IO::AIM->new({
		'base_component' => $base_component,
		'my_config'      => {},
	});
};
like( $@, qr/AIM component requires a/, 'Error when missing screenname and password' );

eval {
	my $aim = whatbot::IO::AIM->new({
		'base_component' => $base_component,
		'my_config'      => {
			'screenname' => 'foo',
		},
	});
};
like( $@, qr/AIM component requires a/, 'Error when missing password' );

eval {
	my $aim = whatbot::IO::AIM->new({
		'base_component' => $base_component,
		'my_config'      => {
			'password' => 'foo',
		},
	});
};
like( $@, qr/AIM component requires a/, 'Error when missing screenname' );

done_testing();

1;
