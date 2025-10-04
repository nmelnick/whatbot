class Stack {
  constructor() {
    this.cards = [];
    this.discard = [];
  }

  shuffle(iterations = 1) {
    for (let i = 0; i < iterations; i++) {
      const seen = {};
      const newCards = [];
      const stackSize = this.cards.length;
      
      while (Object.keys(seen).length < stackSize) {
        let index = -1;
        while (index < 0 || seen[index]) {
          index = Math.floor(Math.random() * stackSize);
        }
        newCards.push(this.cards[index]);
        seen[index] = true;
      }
      
      this.cards = newCards;
    }
  }

  cardCount() {
    return this.cards.length;
  }

  take() {
    const card = this.cards.shift();
    this.discard.push(card);
    return card;
  }
}

export default Stack;
