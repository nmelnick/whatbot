import Command from './Command.js';

class Bother extends Command {
  constructor(config) {
    super(config);
    this.timers = {};
  }

  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.globalRegEx(/^(bother|bug) (\w+) about (.*?) every (.*)$/i, 'bother');
    this.globalRegEx(/^stop b(ugg|other)ing me$/i, 'stop');
    this.globalRegEx(/^stop b(ugg|other)ing (\w+)$/i, 'stopUser');
    
    this.initTimers();
  }

  async bother(message, captures) {
    const [word, user, about, everyStr] = captures;
    const every = this._parseEvery(everyStr);
    
    if (isNaN(every) || every <= 0) {
      return 'I am only going to worry about whole numbers greater than zero.';
    }

    const added = await this.model('Bother').add(user, about, every, message.origin);
    this.queueTimer(added);
    
    return `I will ${word.toLowerCase()} ${this.tagUser(user)} about "${about}" every ${every} seconds.`;
  }

  async stop(message) {
    return this.doStop(message.from);
  }

  async stopUser(message, captures) {
    const user = captures[1];
    if (user === 'me') return null;
    return this.doStop(user);
  }

  async doStop(user) {
    const count = await this.model('Bother').acknowledgeAllFor(user);
    
    if (count && count.length > 0) {
      for (const bother of count) {
        this.dequeueTimer(bother);
      }
      return `I will stop bugging ${this.tagUser(user)}.`;
    }
    
    return `I am not bugging ${user} about anything.`;
  }

  notifyBother(user, about, origin) {
    const bug = `Hey, ${this.tagUser(user)}. I am bugging you about ${about}.`;
    const channel = origin.replace(/^.*?:/, '');
    
    this.sendMessage(origin, {
      from: 'me',
      to: 'public',
      content: bug,
      invisible: true
    });
  }

  async initTimers() {
    const bothers = await this.model('Bother').getActive();
    for (const bother of bothers) {
      this.queueTimer(bother);
    }
  }

  queueTimer(record) {
    const timer = setInterval(() => {
      this.notifyBother(record.user, record.about, record.origin);
    }, record.every * 1000);
    
    const key = `${record.user}-${record.about}`;
    this.timers[key] = timer;
  }

  dequeueTimer(record) {
    const key = `${record.user}-${record.about}`;
    if (this.timers[key]) {
      clearInterval(this.timers[key]);
      delete this.timers[key];
    }
  }

  _parseEvery(capture) {
    if (/^\d+$/.test(capture)) {
      return parseInt(capture);
    }

    if (/^[a-zA-Z]+$/.test(capture)) {
      capture = '1 ' + capture;
    }

    const parts = capture.split(/\s+/);
    let amount = parseInt(parts[0]);
    const unit = parts[1];

    if (unit.match(/^seconds?/)) {
      // already in seconds
    } else if (unit.match(/^minutes?/)) {
      amount *= 60;
    } else if (unit.match(/^hours?/)) {
      amount *= 60 * 60;
    } else if (unit.match(/^days?/)) {
      amount *= 60 * 60 * 24;
    } else if (unit.match(/^weeks?/)) {
      amount *= 60 * 60 * 24 * 7;
    } else if (unit.match(/^months?/)) {
      amount *= 60 * 60 * 24 * 30;
    } else {
      return NaN;
    }

    return amount;
  }

  help() {
    return [
      'Bug will bug one or more users about any topic until they stop it.',
      ' * "bug <user> about <topic> every <interval>" - bug user about topic',
      ' * "stop bugging me" - acknowledge bothers and stop',
      ' * "stop bugging <user>" - stop bugging another user'
    ];
  }
}

export default Bother;
