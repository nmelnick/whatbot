import Shoe from './Stack/Shoe.js';
import Hand from './Hand.js';

class Game {
  constructor() {
    this.players = {};
    this.bets = {};
    this.playerOrder = [];
    this.hands = null;
    this.shoe = null;
    this.activeShoe = 0;
  }

  player(playerName) {
    return this.players[playerName] !== undefined 
      ? (this.players[playerName] / 100).toFixed(2) 
      : undefined;
  }

  addPlayer(player, buyIn) {
    if (this.players[player]) return false;
    
    this.players[player] = Math.floor(buyIn * 100);
    this.playerOrder.push(player);
    return true;
  }

  removePlayer(player) {
    delete this.players[player];
    this.playerOrder = this.playerOrder.filter(p => p !== player);
    return true;
  }

  start(options) {
    if (!options || !options.players) return;
    
    const buyIn = options.buy_in || 100;
    
    for (const player of options.players) {
      this.addPlayer(player, buyIn);
    }
    
    return this.reshoe();
  }

  reshoe() {
    this.shoe = new Shoe(4);
    this.activeShoe = 1;
  }

  deal(players) {
    const hands = [];
    const dealerHand = new Hand({ player: 'Dealer' });
    hands.push(dealerHand);
    
    this.bets = {};
    
    for (const player of this.playerOrder) {
      if (!players[player]) continue;
      
      const bet = Math.floor(players[player] * 100);
      if (!this.players[player] || bet < 1) continue;
      
      this.bets[player] = bet;
      this.players[player] -= bet;
      
      const hand = new Hand({ player });
      hands.push(hand);
    }
    
    if (hands.length <= 1) return null;
    
    // Deal 2 cards to each hand
    for (let i = 0; i < 2; i++) {
      for (const hand of hands) {
        this.hit(hand);
      }
    }
    
    // Check if shoe needs replacing
    if (this.shoe.cardCount() < Object.keys(this.players).length * 3) {
      this.activeShoe = 0;
    }
    
    this.hands = hands;
    return hands;
  }

  collectHand(hand) {
    const index = this.findHand(hand);
    if (index < 0) return false;
    
    this.hands[index] = hand;
    return true;
  }

  finishHand() {
    if (!this.hands) return false;
    
    const dealer = this.hands.shift();
    if (!dealer) return false;
    
    for (const hand of this.hands) {
      if (hand.busted()) {
        continue;
      } else if (dealer.busted()) {
        this.players[hand.player] += Math.floor(this.bets[hand.player] * 2);
      } else if (hand.score() === dealer.score() && !hand.blackjack()) {
        this.players[hand.player] += Math.floor(this.bets[hand.player]);
      } else if (hand.blackjack()) {
        const score = this.bets[hand.player] + (this.bets[hand.player] * (3/2));
        this.players[hand.player] += Math.floor(score);
      } else if (hand.score() > dealer.score()) {
        this.players[hand.player] += Math.floor(this.bets[hand.player] * 2);
      }
    }
    
    for (const player in this.players) {
      if (this.players[player] < 1) {
        this.players[player] = 0;
      }
    }
    
    return true;
  }

  hit(hand) {
    hand.give(this.shoe.take());
  }

  canSplit(hand) {
    return hand.canSplit() && 
           this.players[hand.player] >= this.bets[hand.player];
  }

  split(hand) {
    if (!this.canSplit(hand)) return null;
    
    this.players[hand.player] -= Math.floor(this.bets[hand.player]);
    
    const firstHand = hand.clone();
    firstHand.give(hand.first());
    this.hit(firstHand);
    
    const secondHand = hand.clone();
    secondHand.give(hand.second());
    this.hit(secondHand);
    
    const handIndex = this.findHand(hand);
    this.hands[handIndex] = firstHand;
    this.hands.splice(handIndex + 1, 0, secondHand);
    
    return [firstHand, secondHand];
  }

  canDouble(hand) {
    return hand.canDouble() && 
           this.players[hand.player] >= this.bets[hand.player];
  }

  double(hand) {
    if (!this.canDouble(hand)) return false;
    
    const bet = Math.floor(this.bets[hand.player]);
    this.players[hand.player] -= bet;
    this.bets[hand.player] += bet;
    hand.lastDraw = true;
    this.hit(hand);
    return true;
  }

  findHand(hand) {
    for (let i = 0; i < this.hands.length; i++) {
      if (hand.fingerprint() === this.hands[i].fingerprint()) {
        return i;
      }
    }
    return -1;
  }

  dealerHand(hand) {
    if (hand.player !== 'Dealer' || hand.blackjack()) return false;
    
    while (hand.score() < 17) {
      this.hit(hand);
    }
    
    this.collectHand(hand);
    return true;
  }
}

export default Game;
