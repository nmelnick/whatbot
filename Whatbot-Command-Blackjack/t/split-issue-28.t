use strict;
use warnings;
use Test::More;
use Whatbot::Test;
use Whatbot::Command::Blackjack::Card;
use Whatbot::Command::Blackjack::Hand;

use_ok( 'Whatbot::Command::Blackjack', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

ok( my $jack = Whatbot::Command::Blackjack->new({
	'my_config'      => {},
	'name'           => 'Blackjack',
}), 'new' );

$jack->register();

ok(
	$jack->play(
		Whatbot::Message->new({
			from => 'test',
			to   => '',
			content => '',
		}),
		[ 136 ]
	),
	'play'
);
ok(
	$jack->add_player(
		Whatbot::Message->new({
			from => 'test',
			to   => '',
			content => '',
		})
	),
	'me'
);
ok(
	$jack->start(
		Whatbot::Message->new({
			from => 'test',
			to   => '',
			content => '',
		})
	),
	'start'
);
ok(
	$jack->bet(
		Whatbot::Message->new({
			from => 'test',
			to   => '',
			content => 'bj bet 40',
		}),
		[40],
	),
	'bet'
);
my $dealer_hand = Whatbot::Command::Blackjack::Hand->new(
	'player' => 'Dealer',
	'cards'  => [
		Whatbot::Command::Blackjack::Card->new({ value => 3, suit => 'spades' }),
		Whatbot::Command::Blackjack::Card->new({ value => 6, suit => 'hearts' }),
	]
);
my $player_hand = Whatbot::Command::Blackjack::Hand->new(
	'player' => 'test',
	'cards'  => [
		Whatbot::Command::Blackjack::Card->new({ value => 3, suit => 'clubs' }),
		Whatbot::Command::Blackjack::Card->new({ value => 3, suit => 'clubs' }),
	]
);
$jack->{'dealer_hand'} = $dealer_hand;
$jack->{'active_hand'} = $player_hand;
push(
	@{$jack->game->shoe->cards},
	Whatbot::Command::Blackjack::Card->new({ value => 'J', suit => 'diamonds' }),
	Whatbot::Command::Blackjack::Card->new({ value => 'K', suit => 'diamonds' }),
	Whatbot::Command::Blackjack::Card->new({ value => 'Q', suit => 'spades' }),
	Whatbot::Command::Blackjack::Card->new({ value => 4, suit => 'spades' }),
	Whatbot::Command::Blackjack::Card->new({ value => 7, suit => 'diamonds' }),
	Whatbot::Command::Blackjack::Card->new({ value => 'K', suit => 'clubs' }),
);
ok(
	$jack->hand_action(),
	'action'
);
my $active = $jack->active_hand;
my $messages;
ok(
	$messages = $jack->split(
		Whatbot::Message->new({
			from => 'test',
			to   => '',
			content => '',
		})
	),
	'split'
);
ok( $jack->active_hand ne $active, 'new active hand' );
is( @{ $jack->hands }, 1, '1 hand waiting' );
ok( $messages->[0] =~ /^test\:/, 'message to test' );
is( $jack->active_hand->player, 'test', 'active hand to test' );
is( $jack->hands->[0]->player, 'test', 'next hand to test' );

done_testing();

1;
