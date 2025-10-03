const SUITS = {
  diamonds: {
    color: 'red',
    uni: '\u2666'
  },
  hearts: {
    color: 'red',
    uni: '\u2665'
  },
  clubs: {
    color: 'black',
    uni: '\u2663'
  },
  spades: {
    color: 'black',
    uni: '\u2660'
  }
};

export function suits() {
  return SUITS;
}
