import Command from './Command.js';

class Insult extends Command {
  constructor(options) {
    super(options);
    this.lastInsult = 'rand';
    this.insults = [
      'idiot',
      'wanker',
      'douchebag',
      'moron',
      'asshat',
      'jackass'
    ];
  }

  register() {
    this.priority = 'Primary';
    this.requireDirect = false;

    const config = this.my_config;
    if (config && config.insults) {
      const additionalInsults = config.insults.split(/,\s*/);
      this.insults.push(...additionalInsults);
    }
  }

  getInsult() {
    let insult = this.lastInsult;
    
    while (insult === this.lastInsult) {
      insult = this.insults[Math.floor(Math.random() * this.insults.length)];
    }
    
    this.lastInsult = insult;
    return insult;
  }

  parseMessage(message, captures) {
    if (!captures || !captures[0]) return null;
    
    const insult = this.getInsult();
    const article = /^[aeiou]/.test(insult) ? 'n' : '';
    
    return `${captures[0]}, you are a${article} ${insult}.`;
  }

  help() {
    return 'Insult provides creative insults on command. Usage: insult <name>';
  }
}

Insult.prototype.parseMessage.isCommandRegEx = true;
Insult.prototype.parseMessage.pattern = /(@?\w+)/;

export default Insult;
