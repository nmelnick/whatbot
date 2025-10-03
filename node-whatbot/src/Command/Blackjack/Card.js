import { suits } from './Constants.js';

class Card {
  constructor({ value, suit }) {
    this.value = value;
    this.suit = suit;
    const suitInfo = suits()[suit];
    this.color = suitInfo.color;
    this.unicode = suitInfo.uni;
  }

  ircize() {
    return this.value + this.unicode;
  }
}

export default Card;
