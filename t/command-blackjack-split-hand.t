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
    })
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
  $jack->add_player(
    Whatbot::Message->new({
      from => 'test2',
      to   => '',
      content => '',
    })
  ),
  'me2'
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
      content => 'bj bet 0.01',
    }),
    ['0.01'],
  ),
  'bet'
);
ok(
  $jack->bet(
    Whatbot::Message->new({
      from => 'test2',
      to   => '',
      content => 'bj bet 0.01',
    }),
    ['0.01'],
  ),
  'bet2'
);
my $dealer_hand = Whatbot::Command::Blackjack::Hand->new(
  'player' => 'Dealer',
  'cards'  => [
    Whatbot::Command::Blackjack::Card->new({ value => 5, suit => 'diamonds' }),
    Whatbot::Command::Blackjack::Card->new({ value => 8, suit => 'clubs' }),
  ]
);
my $player_hand = Whatbot::Command::Blackjack::Hand->new(
  'player' => 'test',
  'cards'  => [
    Whatbot::Command::Blackjack::Card->new({ value => 6, suit => 'diamonds' }),
    Whatbot::Command::Blackjack::Card->new({ value => 6, suit => 'clubs' }),
  ]
);
my $player2_hand = Whatbot::Command::Blackjack::Hand->new(
  'player' => 'test',
  'cards'  => [
    Whatbot::Command::Blackjack::Card->new({ value => 8, suit => 'diamonds' }),
    Whatbot::Command::Blackjack::Card->new({ value => 4, suit => 'clubs' }),
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
    Whatbot::Message->new({
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
