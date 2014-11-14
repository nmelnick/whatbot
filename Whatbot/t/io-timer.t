#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

my $test = Whatbot::Test->new();
$test->initialize_state();

use_ok( 'Whatbot::IO::Timer', 'Load Module' );

my $timer = Whatbot::IO::Timer->new({
	'my_config' => {},
});

my $sub1 = sub {
	return 1;
};
my $sub2 = sub {
	return 2;
};
my $ref1 = { foo => 'bar' };
my $ref2 = { bar => 'foo' };

ok( $timer->enqueue( 50, $sub1, $ref1 ), 'enqueue sub1 ref1' );
is( scalar( @{ $timer->time_queue } ), 1, 'has 1 queued' );
is( $timer->time_queue->[0]->[1], $sub1, 'is sub1' );
is( $timer->time_queue->[0]->[2], $ref1, 'is ref1' );
ok( $timer->enqueue( 50, $sub2, $ref2 ), 'enqueue sub2 ref2' );
is( scalar( @{ $timer->time_queue } ), 2, 'has 2 queued' );
is( $timer->time_queue->[1]->[1], $sub2, 'is sub2' );
is( $timer->time_queue->[1]->[2], $ref2, 'is ref2' );
ok( $timer->enqueue( 50, $sub2, $ref1 ), 'enqueue sub2 ref1' );
is( scalar( @{ $timer->time_queue } ), 3, 'has 3 queued' );
is( $timer->time_queue->[2]->[1], $sub2, 'is sub2' );
is( $timer->time_queue->[2]->[2], $ref1, 'is ref1' );
ok( $timer->enqueue( 50, $sub1, $ref2 ), 'enqueue sub1 ref2' );
is( scalar( @{ $timer->time_queue } ), 4, 'has 4 queued' );
is( $timer->time_queue->[3]->[1], $sub1, 'is sub1' );
is( $timer->time_queue->[3]->[2], $ref2, 'is ref2' );

ok( $timer->remove_where_arg( 0, $ref2 ), 'remove all in ref2' );
is( scalar( @{ $timer->time_queue } ), 3, 'has 2 queued' );
is( $timer->time_queue->[1]->[1], $sub2, '0 is sub2' );
is( $timer->time_queue->[1]->[2], $ref1, '0 is ref1' );

done_testing();

1;
