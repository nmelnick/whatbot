#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Cryptocurrency', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $c = Whatbot::Command::Cryptocurrency->new({
  'my_config' => {},
  'name'      => 'Cryptocurrency',
}), 'new' );

$c->register();

is( scalar( @{$c->help()} ), 2, 'help returns two entries' );

ok( $c->get_spot_price( 'BTC', 'USD' ), 'spot price of btc->usd exists' );
ok( $c->get_spot_price( 'LTC', 'USD' ), 'spot price of ltc->usd exists' );
ok( $c->get_spot_price( 'ETH', 'USD' ), 'spot price of eth->usd exists' );
ok( ( not eval { return $c->get_spot_price( 'XP0', 'USD' ) } ), 'spot price of xp0->usd does not exist' );

ok( $c->check_spot( 'BTC', 'usd' ) =~ /1 BTC is worth .+? in USD/, 'check_spot with lower case currency works' );
ok( $c->check_spot( 'BTC', ' usd  ' ) =~ /1 BTC is worth .+? in USD/, 'check_spot with space in currency works' );
is(
  $c->check_spot( 'BTC', 'boo' ),
  'Currency is invalid',
  'check_spot with invalid currency returns human currency error'
);
is(
  $c->check_spot( '', '' ),
  'Invalid from or to currency',
  'check_spot with invalid currencies returns invalid currency error'
);

done_testing();

1;
