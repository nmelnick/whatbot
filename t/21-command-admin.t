#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use whatbot::Test;

use_ok( 'whatbot::Command::Admin', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

ok( my $admin = whatbot::Command::Admin->new({
	'base_component' => $base_component,
	'my_config'      => { 'user' => 'testuser' },
	'name'           => 'Market',
}), 'new' );

$admin->register();

# Permission
ok(
	( not $admin->_has_permission( get_message( '', '' ) ) ),
	'Non valid message no permission'
);
ok(
	( not $admin->_has_permission( get_message( 'foo', 'bar' ) ) ),
	'Invalid user no permission'
);
ok(
	( not $admin->_has_permission( get_message( 'testuser1', 'bar' ) ) ),
	'Invalid user like no permission'
);
ok(
	( not $admin->_has_permission( get_message( 'Testuser', 'bar' ) ) ),
	'Invalid user like no permission 2'
);
ok(
	$admin->_has_permission( get_message( 'testuser', 'bar' ) ),
	'Valid user permission'
);

# Version
like( $admin->version( get_message( 'testuser', '' ) ), qr/whatbot \d.*/, 'version string' );

sub get_message {
	my ( $user, $message ) = @_;

	return whatbot::Message->new({
		'from'    => $user,
		'to'      => 'whatever',
		'content' => $message,
	});
}

done_testing();
