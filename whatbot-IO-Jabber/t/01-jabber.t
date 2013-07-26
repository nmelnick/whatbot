#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::IO::Jabber', 'Load module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

eval {
	my $aim = whatbot::IO::Jabber->new({
		'base_component' => $base_component,
		'my_config'      => {},
	});
};
like( $@, qr/Jabber component requires a/, 'Error when missing jabber_id and password' );

eval {
	my $aim = whatbot::IO::Jabber->new({
		'base_component' => $base_component,
		'my_config'      => {
			'jabber_id' => 'foo@bar.com/resource',
		},
	});
};
like( $@, qr/Jabber component requires a/, 'Error when missing password' );

eval {
	my $aim = whatbot::IO::Jabber->new({
		'base_component' => $base_component,
		'my_config'      => {
			'password' => 'foo',
		},
	});
};
like( $@, qr/Jabber component requires a/, 'Error when missing jabber_id' );

done_testing();

1;
