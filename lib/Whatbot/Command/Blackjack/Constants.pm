package Whatbot::Command::Blackjack::Constants;
use strict;
use warnings;

my %SUITS_INFO = (
  'diamonds'  => {
    'color' => 'red',
    'uni'   => "\x{2666}"
  },
  'hearts'    => {
    'color' => 'red',
    'uni'   => "\x{2665}"
  },
  'clubs'     => {
    'color' => 'black',
    'uni'   => "\x{2663}"
  },
  'spades'    => {
    'color' => 'black',
    'uni'   => "\x{2660}"
  },
);

sub suits {
  return \%SUITS_INFO;
}

1;
