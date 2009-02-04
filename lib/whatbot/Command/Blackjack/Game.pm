package whatbot::Command::Blackjack::Game;
use Moose;

has 'players'       => ( is => 'ro', isa => 'HashRef', default => sub { [] } );
has 'shoe'          => ( is => 'rw', isa => 'whatbot::Command::Blackjack::Stack::Shoe' );
has 'active_shoe'   => ( is => 'rw', isa => 'Int', default => 0 );


1;