#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Whatbot::Test;

use_ok( 'Whatbot::Database::Table::Soup', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

my $soup = Whatbot::Database::Table::Soup->new();
ok( $soup, 'Object created' );

is( $soup->count(), 0, 'table has zero records' );

throws_ok(
  sub { $soup->get() },
  qr/Expected/,
  'get requires one param'
);

is( $soup->get('example'), undef, 'example is empty' );

throws_ok(
  sub { $soup->set('example') },
  qr/Expected/,
  'set requires one param'
);

ok( $soup->set( 'example', 'bar' ), 'set example to bar' );
is( $soup->count(), 1, 'table has one record' );
is( $soup->get('example'), 'bar', 'example is bar' );

is_deeply(
  $soup->get_hashref(),
  {
    'example' => 'bar',
  },
  'get_hashref matches get',
);

throws_ok(
  sub { $soup->clear() },
  qr/Expected/,
  'clear requires one param'
);

$soup->clear('example');
is( $soup->count(), 0, 'table has zero records' );
is( $soup->get('example'), undef, 'example is empty' );

done_testing();
