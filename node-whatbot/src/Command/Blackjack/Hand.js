class Hand {
  constructor({ player }) {
    this.player = player;
    this.cards = [];
    this.lastDraw = false;
  }

  clone() {
    return new Hand({ player: this.player });
  }

  fingerprint() {
    return [
      this.player,
      this.first().value,
      this.first().suit,
      this.second().value,
      this.second().suit
    ].join('');
  }

  ircize() {
    let output = this.player + ': ';
    for (const card of this.cards) {
      output += card.ircize() + '  ';
    }
    output += '(' + this.score() + ').';
    return output;
  }

  first() {
    return this.cards[0];
  }

  second() {
    return this.cards[1];
  }

  give(card) {
    this.cards.push(card);
  }

  busted() {
    return this.score() > 21;
  }

  blackjack() {
    return this.score() === 21 && this.cardCount() === 2;
  }

  cardCount() {
    return this.cards.length;
  }

  hasAce() {
    for (const card of this.cards) {
      if (card.value === 'A') return true;
    }
    return false;
  }

  canDouble() {
    return this.cardCount() === 2 && this.score() > 8 && this.score() < 12;
  }

  canSplit() {
    return this.cardCount() === 2 && this.first().value === this.second().value;
  }

  score() {
    let score = 0;
    const aces = [];
    
    for (const card of this.cards) {
      if (/[KQJ]/.test(card.value)) {
        score += 10;
      } else if (card.value === 'A') {
        aces.push(card);
      } else {
        score += parseInt(card.value);
      }
    }
    
    // Add aces as 1
    for (const ace of aces) {
      score += 1;
    }
    
    // Try to make aces 11
    for (const ace of aces) {
      if (score + 10 <= 21) {
        score += 10;
      }
    }
    
    return score;
  }
}

export default Hand;
