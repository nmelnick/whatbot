import Command from './Command.js';
import Game from './Blackjack/Game.js';

class Blackjack extends Command {
  constructor(options) {
    super(options);
    this.game = null;
    this.gameAdmin = null;
    this.bets = {};
    this.dealerHand = null;
    this.activeHand = null;
    this.hands = [];
    this.buyIn = 100;
    this.waitingForBets = false;
  }

  register() {
    this.priority = 'Extension';
    this.requireDirect = false;
    
    this.command('play');
    this.command('end');
    this.command('hax');
    this.command('deal');
    this.command('help');
    this.globalRegEx(/^bj? me$/i, 'addPlayer');
    this.globalRegEx(/^bj? start$/i, 'start');
    this.globalRegEx(/^bj? amounts/i, 'amounts');
    this.globalRegEx(/^bj? bet \$?(\d+(\.\d\d)?)$/i, 'bet');
    this.globalRegEx(/^bj? (h|hit)$/i, 'hit');
    this.globalRegEx(/^bj? (s|stand)$/i, 'stand');
    this.globalRegEx(/^bj? (d|double)$/i, 'double');
    this.globalRegEx(/^bj? (p|split)$/i, 'split');
  }

  help() {
    return [
      'Blackjack is a game of blackjack for whatbot. To begin, give the command "blackjack play". Blackjack will prompt you from there.',
      'As a quick reference, once you initiate a game, enter "b me" to add yourself to a game, and the initiater can do "b start" to start the game.',
      'At any time, you can type "b amounts" to see your holdings.',
      'You can add yourself to an existing game at any time by saying "b me".',
      'Standard rules. Double/Split offered, Blackjack pays 3:2, default buy in is $100.',
      'To end an existing game, give the command "blackjack end".'
    ];
  }

  async play(message, captures) {
    if (this.game) {
      return 'Blackjack game already active.';
    }
    
    this.gameAdmin = message.from;
    const buyIn = captures && captures[0] ? parseInt(captures[0]) : null;
    
    this.game = new Game();
    if (buyIn) this.buyIn = buyIn;
    
    return `Blackjack time, buy in is $${this.buyIn}. Anyone who wants to play, type "b me". ${message.from}, type "b start" when everyone is ready.`;
  }

  async addPlayer(message) {
    if (!this.game) {
      return null;
    }
    
    if (this.game.addPlayer(message.from, this.buyIn)) {
      return `Gotcha, ${message.from}.`;
    } else {
      return `Already got you, ${message.from}${this.generateInsult()}.`;
    }
  }

  async start(message) {
    if (!this.game) {
      return null;
    }
    
    if (message.from !== this.gameAdmin) {
      return null;
    }
    
    if (Object.keys(this.game.players).length === 0) {
      return `I need players before you can deal${this.generateInsult()}.`;
    }
    
    this.game.start({ buy_in: this.buyIn });
    return this.newHand();
  }

  async end() {
    if (!this.game) return null;
    
    this.game = null;
    this.gameAdmin = null;
    this.bets = {};
    this.dealerHand = null;
    this.activeHand = null;
    this.hands = [];
    this.buyIn = 100;
    
    return 'Alright, fine, no more game for you.';
  }

  async hax(message, captures) {
    if (!this.game || message.from !== this.gameAdmin) return null;
    
    const [player, amount] = captures[0].split(' ');
    
    if (!player || !this.game.players[player]) {
      return `Player "${player}" doesn't exist${this.generateInsult()}.`;
    }
    
    if (!amount || !/^\d+$/.test(amount)) {
      return `What is "${amount}"${this.generateInsult()}.`;
    }
    
    this.game.players[player] = parseInt(amount) * 100;
    return 'Hax enabled. ' + this.amounts();
  }

  amounts() {
    if (!this.game) return null;
    
    const playerList = Object.keys(this.game.players).map(player => 
      `${player} with $${this.game.player(player)}`
    ).join(', ');
    
    return 'Players: ' + playerList;
  }

  async bet(message, captures) {
    if (!this.waitingForBets) return null;
    
    let bet = parseFloat(captures[0]);
    if (bet < 0.01) bet = 0;
    
    if (!this.game.players[message.from]) {
      return `You have not bought in, ${message.from}.`;
    }
    
    if (this.game.player(message.from) < bet) {
      return `You cannot bet $${bet}, ${message.from}, you only have $${this.game.player(message.from)}.`;
    }
    
    this.bets[message.from] = bet;
    
    if (Object.keys(this.bets).length === Object.keys(this.game.players).length) {
      return this.deal();
    }
    
    return `Okay, ${message.from}.`;
  }

  async deal() {
    if (!this.game || !this.game.activeShoe) return null;
    
    this.waitingForBets = false;
    this.hands = this.game.deal(this.bets);
    
    if (!this.hands) {
      return this.newHand();
    }
    
    this.dealerHand = this.hands.shift();
    
    if (this.dealerHand.blackjack && this.dealerHand.blackjack()) {
      const messages = [];
      for (const hand of this.hands) {
        messages.push(hand.ircize());
      }
      messages.push(this.dealerHand.ircize());
      messages.push(`Dealer has Blackjack. Thank you for all of your money${this.generateInsult(true)}.`);
      return this.newHand(messages);
    }
    
    const dealerView = 'Dealer shows ' + this.dealerHand.first().ircize() + '.';
    return this.nextHand([dealerView]);
  }

  async hit(message) {
    if (!this.activeHand) return null;
    
    if (message.from !== this.activeHand.player) {
      return `Not your turn${this.generateInsult()}.`;
    }
    
    this.game.hit(this.activeHand);
    return this.handAction();
  }

  async stand(message) {
    if (!this.activeHand) return null;
    
    if (message.from !== this.activeHand.player) {
      return `Not your turn${this.generateInsult()}.`;
    }
    
    this.game.collectHand(this.activeHand);
    return this.nextHand();
  }

  async double(message) {
    if (!this.activeHand || !this.game.canDouble(this.activeHand)) return null;
    
    if (message.from !== this.activeHand.player) {
      return `Not your turn${this.generateInsult()}.`;
    }
    
    this.game.double(this.activeHand);
    return this.handAction();
  }

  async split(message) {
    if (!this.activeHand || !this.game.canSplit(this.activeHand)) return null;
    
    if (message.from !== this.activeHand.player) {
      return `Not your turn${this.generateInsult()}.`;
    }
    
    const hands = this.game.split(this.activeHand);
    this.activeHand = hands[0];
    this.hands.unshift(hands[1]);
    return this.handAction();
  }

  newHand(messages = []) {
    const msgs = [...messages];
    
    if (this.game.activeShoe !== 1) {
      msgs.push('We now have a new shoe of cards.');
      this.game.reshoe();
    }
    
    this.game.finishHand();
    this.waitingForBets = true;
    this.bets = {};
    
    if (this.game.players) {
      msgs.push(this.amounts());
    }
    
    for (const player in this.game.players) {
      if (this.game.players[player] === 0) {
        msgs.push(`See ya later, ${player}.`);
        this.game.removePlayer(player);
      }
    }
    
    if (Object.keys(this.game.players).length === 0) {
      msgs.push(`No more players. Good work${this.generateInsult(true)}.`);
      this.end();
      return msgs;
    }
    
    msgs.push('New hand: Place your bets by typing "b bet amount" where amount is your actual numeric bet. If you want to sit this out, hit b bet 0.');
    return msgs;
  }

  nextHand(messages = []) {
    const hand = this.hands.shift();
    
    if (!hand) {
      const msgs = [...messages];
      this.game.dealerHand(this.dealerHand);
      let output = this.dealerHand.ircize();
      
      if (this.dealerHand.busted()) {
        output += ' Dealer busts.';
      } else if (this.dealerHand.score() === 21) {
        output += ' WOO.';
      }
      
      msgs.push(output);
      return this.newHand(msgs);
    }
    
    this.activeHand = hand;
    return this.handAction(messages);
  }

  handAction(messages = []) {
    const msgs = [...messages];
    const hand = this.activeHand;
    let output = hand.ircize();
    
    if (hand.blackjack()) {
      output += ' Congratulations, you got blackjack.';
      msgs.push(output);
      this.game.collectHand(hand);
      return this.nextHand(msgs);
    } else if (hand.busted()) {
      output += ` Good job, you busted${this.generateInsult()}.`;
      msgs.push(output);
      this.game.collectHand(hand);
      return this.nextHand(msgs);
    } else if (hand.score() === 21) {
      output += ' Hey, you didn\'t bust.';
      msgs.push(output);
      this.game.collectHand(hand);
      return this.nextHand(msgs);
    } else if (hand.lastDraw) {
      output += ` Enjoy your lots${this.generateInsult()}.`;
      msgs.push(output);
      this.game.collectHand(hand);
      return this.nextHand(msgs);
    } else {
      output += ' Start with "b", then h/hit s/stand';
      if (this.game.canDouble(hand)) output += ' d/double';
      if (this.game.canSplit(hand)) output += ' p/split';
      output += '.';
      msgs.push(output);
      return msgs;
    }
  }

  generateInsult(isPlural = false) {
    const config = this.my_config;
    if (!config || !config.insult) return '.';
    
    const insultCommand = this.controller?.commandShortName?.insult;
    if (!insultCommand) return '.';
    
    let insult = insultCommand.getInsult();
    
    if (isPlural) {
      insult += insult.endsWith('s') ? 'es' : 's';
    } else {
      insult = 'you ' + insult;
    }
    
    return ', ' + insult + '.';
  }
}

export default Blackjack;
