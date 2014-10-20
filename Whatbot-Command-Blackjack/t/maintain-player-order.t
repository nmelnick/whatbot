use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Blackjack::Game', 'Load Game Module' );

my $game = Whatbot::Command::Blackjack::Game->new();

$game->add_player( 'user1', 100 );
ok( $game->players->{'user1'}, 'has user1' );
is( scalar( @{ $game->player_order } ), 1, 'has 1 player' );
$game->add_player( 'user2', 100 );
ok( $game->players->{'user2'}, 'has user2' );
is( scalar( @{ $game->player_order } ), 2, 'has 2 players' );
$game->add_player( 'user3', 100 );
ok( $game->players->{'user3'}, 'has user3' );
is( scalar( @{ $game->player_order } ), 3, 'has 3 players' );
$game->add_player( 'userex', 100 );
ok( $game->players->{'userex'}, 'has userex' );
is( scalar( @{ $game->player_order } ), 4, 'has 4 players' );
$game->add_player( 'user4', 100 );
ok( $game->players->{'user4'}, 'has user4' );
is( scalar( @{ $game->player_order } ), 5, 'has 5 players' );
$game->remove_player('userex');
ok( ! $game->players->{'userex'}, 'no longer has userex' );
is( scalar( @{ $game->player_order } ), 4, 'has 4 players' );
is( $game->player_order->[0], 'user1', '0 user1' );
is( $game->player_order->[1], 'user2', '1 user2' );
is( $game->player_order->[2], 'user3', '2 user3' );
is( $game->player_order->[3], 'user4', '3 user4' );

$game->start();
$game->reshoe();
$game->finish_hand();

for ( my $i = 0; $i < 1000; $i++ ) {
	my %bets;
	foreach my $player ( qw( user1 user2 user3 user4 ) ) {
		$bets{$player} = '0.01';
	}
	my $hands = $game->deal(\%bets);
	unless ($hands) {
		$game->finish_hand();
		next;
	}
	my $dealer_hand = shift( @$hands );
	is( $hands->[0]->player, 'user1', 'iter ' . $i . ' hand 0 user1' );
	is( $hands->[1]->player, 'user2', 'iter ' . $i . ' hand 1 user2' );
	is( $hands->[2]->player, 'user3', 'iter ' . $i . ' hand 2 user3' );
	is( $hands->[3]->player, 'user4', 'iter ' . $i . ' hand 3 user4' );
}

done_testing();

1;
