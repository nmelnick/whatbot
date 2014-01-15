#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use whatbot::Test;
use_ok( 'whatbot::Database::Table::UserAlias', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

my $url = whatbot::Database::Table::UserAlias->new( base_component => $base_component );
ok( $url, 'Object created' );

is( $url->count(), 0, 'table has zero records' );

ok( $url->alias( 'foo', 'bar' ), 'alias bar to foo' );
ok( ! $url->alias( 'foo', 'bar' ), 'cannot duplicate alias' );

is( $url->count(), 1, 'table has one record' );

ok( $url->remove( 'foo', 'bar' ), 'remove bar alias' );
ok( ! $url->remove( 'foo', 'bar' ), 'cannot remove alias that does not exist' );
is( $url->count(), 0, 'table has zero records' );

ok( $url->alias( 'foo', 'baz' ), 'alias baz to foo' );
is( $url->count(), 1, 'table has one record' );
is( $url->user_for_alias('baz'), 'foo', 'alias baz is user foo' );
is( $url->aliases_for_user('foo')->[0], 'baz', 'user foo has alias baz' );
ok( $url->alias( 'foo', 'bar' ), 'alias bar to foo' );
is( $url->count(), 2, 'table has two records' );
is( $url->user_for_alias('bar'), 'foo', 'alias bar is user foo' );
is( $url->aliases_for_user('foo')->[0], 'baz', 'user foo has alias baz' );
is( $url->aliases_for_user('foo')->[1], 'bar', 'user foo has alias bar' );
is( $url->related_users('foo')->[0], 'baz', 'user foo has related baz' );
is( $url->related_users('foo')->[1], 'bar', 'user foo has related bar' );

ok( $url->remove('foo'), 'remove all aliases for foo' );
is( $url->count(), 0, 'table has zero records' );

done_testing();
