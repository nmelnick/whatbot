#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

require_ok( 'Whatbot::Command::Admin' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $admin = Whatbot::Command::Admin->new({
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

  return Whatbot::Message->new({
    'from'    => $user,
    'to'      => 'whatever',
    'content' => $message,
  });
}

done_testing();
