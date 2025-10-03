import Stack from '../Stack.js';
import Deck from './Deck.js';

class Shoe extends Stack {
  constructor(decks = 4) {
    super();
    
    this.decks = decks;
    const cards = [];
    
    for (let i = 0; i < this.decks; i++) {
      const deck = new Deck();
      cards.push(...deck.cards);
    }
    
    this.cards = cards;
    this.shuffle();
    this.shuffle();
  }
}

export default Shoe;
