#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::IO::Jabber', 'Load module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

eval {
	my $jab = Whatbot::IO::Jabber->new({
		'my_config'      => {},
	});
};
like( $@, qr/Jabber component requires a/, 'Error when missing jabber_id and password' );

eval {
	my $jab = Whatbot::IO::Jabber->new({
		'my_config'      => {
			'jabber_id' => 'foo@bar.com/resource',
		},
	});
};
like( $@, qr/Jabber component requires a/, 'Error when missing password' );

eval {
	my $jab = Whatbot::IO::Jabber->new({
		'my_config'      => {
			'password' => 'foo',
		},
	});
};
like( $@, qr/Jabber component requires a/, 'Error when missing jabber_id' );

done_testing();

1;
