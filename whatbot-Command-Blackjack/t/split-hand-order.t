use strict;
use warnings;
use Test::More;
use whatbot::Test;
use whatbot::Command::Blackjack::Card;
use whatbot::Command::Blackjack::Hand;

use_ok( 'whatbot::Command::Blackjack', 'Load Module' );

my $test = whatbot::Test->new();
$test->initialize_state();

ok( my $jack = whatbot::Command::Blackjack->new({
	'my_config'      => {},
	'name'           => 'Blackjack',
}), 'new' );

$jack->register();

ok(
	$jack->play(
		whatbot::Message->new({
			from => 'test',
			to   => '',
			content => '',
		})
	),
	'play'
);
ok(
	$jack->add_player(
		whatbot::Message->new({
			from => 'test',
			to   => '',
			content => '',
		})
	),
	'me'
);
ok(
	$jack->add_player(
		whatbot::Message->new({
			from => 'test2',
			to   => '',
			content => '',
		})
	),
	'me2'
);
ok(
	$jack->start(
		whatbot::Message->new({
			from => 'test',
			to   => '',
			content => '',
		})
	),
	'start'
);
ok(
	$jack->bet(
		whatbot::Message->new({
			from => 'test',
			to   => '',
			content => 'bj bet 0.01',
		}),
		['0.01'],
	),
	'bet'
);
ok(
	$jack->bet(
		whatbot::Message->new({
			from => 'test2',
			to   => '',
			content => 'bj bet 0.01',
		}),
		['0.01'],
	),
	'bet2'
);
my $dealer_hand = whatbot::Command::Blackjack::Hand->new(
	'player' => 'Dealer',
	'cards'  => [
		whatbot::Command::Blackjack::Card->new({ value => 5, suit => 'diamonds' }),
		whatbot::Command::Blackjack::Card->new({ value => 8, suit => 'clubs' }),
	]
);
my $player_hand = whatbot::Command::Blackjack::Hand->new(
	'player' => 'test',
	'cards'  => [
		whatbot::Command::Blackjack::Card->new({ value => 6, suit => 'diamonds' }),
		whatbot::Command::Blackjack::Card->new({ value => 6, suit => 'clubs' }),
	]
);
my $player2_hand = whatbot::Command::Blackjack::Hand->new(
	'player' => 'test',
	'cards'  => [
		whatbot::Command::Blackjack::Card->new({ value => 8, suit => 'diamonds' }),
		whatbot::Command::Blackjack::Card->new({ value => 4, suit => 'clubs' }),
	]
);

$jack->{'dealer_hand'} = $dealer_hand;
$jack->{'hands'} = [ $player2_hand ];
$jack->{'active_hand'} = $player_hand;
ok(
	$jack->hand_action(),
	'action'
);
my $active = $jack->active_hand;
my $messages;
ok(
	$messages = $jack->split(
		whatbot::Message->new({
			from => 'test',
			to   => '',
			content => '',
		})
	),
	'split'
);
ok( $jack->active_hand ne $active, 'new active hand' );
is( @{ $jack->hands }, 2, '2 hands waiting' );
ok( $messages->[0] =~ /^test\:/, 'message to test' );
is( $jack->active_hand->player, 'test', 'active hand to test' );
is( $jack->hands->[0]->player, 'test', 'next hand to test' );

done_testing();

1;
