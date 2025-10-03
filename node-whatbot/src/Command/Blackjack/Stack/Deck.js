import Stack from '../Stack.js';
import Card from '../Card.js';
import { suits } from '../Constants.js';

class Deck extends Stack {
  constructor() {
    super();
    
    const suitNames = Object.keys(suits());
    const cards = [];
    
    for (const suit of suitNames) {
      const values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
      for (const value of values) {
        cards.push(new Card({ value, suit }));
      }
    }
    
    this.cards = cards;
    this.shuffle();
  }
}

export default Deck;
