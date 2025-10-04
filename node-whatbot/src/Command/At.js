import Command from './Command.js';

class At extends Command {
  constructor(config) {
    super(config);
    this.atList = {};
    this.everyList = {};
    this.nextAtId = 1;
    this.nextEveryId = 1;
  }

  register() {
    this.priority = 'Extension';
    this.requireDirect = true;

    this.commandRegEx('^([^,]+), (.+)$', 'parseMessage');
    this.globalRegEx(/^every ([^,]+), ([^,]+), (.+)$/i, 'parseEvery');
    this.globalRegEx(/^at list$/i, 'doAtList');
    this.globalRegEx(/^every list$/i, 'doEveryList');
    this.globalRegEx(/^(every|at) delete (\d+)$/i, 'doDelete');
  }

  async parseMessage(message, captures) {
    const [timespec, doWhat] = captures;
    
    const time = this._parseTime(timespec);
    if (!time) {
      return `wtf is '${timespec}'`;
    }

    const now = Date.now();
    if (time <= now) {
      const nowStr = new Date(now).toISOString();
      return `that time is in the past. right now it's ${nowStr} for me.`;
    }

    this.log.write(`Creating -at- for time: ${new Date(time).toISOString()}`);

    const medium = message.origin;
    const id = this.nextAtId++;

    const queuespec = [Math.floor(time / 1000), this._runAt.bind(this), medium, message.from, doWhat, id];
    
    this.timer.enqueue(...queuespec);

    this.atList[id] = [new Date(time), doWhat, message.from, queuespec];

    const timeStr = new Date(time).toISOString().replace('T', ' at ').split('.')[0];
    return `OK, I will do that on ${timeStr}. (at #${id})`;
  }

  async parseEvery(message, captures) {
    const [periodspec, validityspec, doWhat] = captures;

    return 'Every scheduling not yet implemented - needs Timer integration';
  }

  async doAtList(message) {
    const out = [];
    
    for (const id of Object.keys(this.atList).sort()) {
      const [time, doWhat, who] = this.atList[id];
      out.push(`${id}. ${doWhat} (at ${time.toISOString()}, from ${who})`);
    }

    if (out.length === 0) {
      return 'the at list is empty.';
    }

    return out;
  }

  async doEveryList(message) {
    const out = [];
    
    for (const id of Object.keys(this.everyList).sort()) {
      const [periodspec, endtime, doWhat, who] = this.everyList[id];
      out.push(`${id}. ${doWhat} (every ${periodspec} until ${endtime}, from ${who})`);
    }

    if (out.length === 0) {
      return 'the every list is empty.';
    }

    return out;
  }

  async doDelete(message, captures) {
    const doEvery = captures[0].toLowerCase() === 'every';
    const id = parseInt(captures[1]);

    if (doEvery) {
      if (!this.everyList[id]) {
        return `there is no every #${id}.`;
      } else {
        const removed = this.timer.remove(...this.everyList[id][4]);
        if (!removed) {
          return 'unable to remove?! :(';
        }
        delete this.everyList[id];
        return `deleted every #${id}.`;
      }
    } else {
      if (!this.atList[id]) {
        return `there is no at #${id}.`;
      } else {
        const removed = this.timer.remove(...this.atList[id][3]);
        if (!removed) {
          return 'unable to remove?! :(';
        }
        delete this.atList[id];
        return `deleted at #${id}.`;
      }
    }
  }

  _runAt(medium, from, what, id) {
    this.dispatchMessage(medium, {
      from: from,
      to: 'public',
      content: what,
      invisible: true
    });
    delete this.atList[id];
  }

  _parseTime(timespec) {
    timespec = timespec.trim();
    
    const relativeMinutes = timespec.match(/^(\d+)\s*(?:minutes?|mins?)$/i);
    if (relativeMinutes) {
      return Date.now() + (parseInt(relativeMinutes[1]) * 60 * 1000);
    }

    const relativeHours = timespec.match(/^(\d+)\s*(?:hours?|hrs?)$/i);
    if (relativeHours) {
      return Date.now() + (parseInt(relativeHours[1]) * 60 * 60 * 1000);
    }

    const absoluteTime = new Date(timespec);
    if (!isNaN(absoluteTime.getTime())) {
      return absoluteTime.getTime();
    }

    return null;
  }

  help() {
    return [
      'at/every works like "whatbot, at <time>, <input>"',
      'for listing stuff, "whatbot, at list". delete things with "whatbot, at delete <#>"',
      'Examples:',
      ' * "at 5 minutes, say hello" - in 5 minutes, say hello',
      ' * "at 2pm, remind everyone about the meeting" - at 2pm today',
      ' * "at 2023-12-25 10:00, merry christmas!" - specific date/time'
    ];
  }
}

export default At;
