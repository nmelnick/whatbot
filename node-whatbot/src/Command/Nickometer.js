import Command from './Command.js';

class Nickometer extends Command {
  constructor(options) {
    super(options);
    this.score = 0;
  }

  register() {
    this.priority = 'Extension';
    this.requireDirect = false;
  }

  parseMessage(message, captures) {
    const nickometer = captures && captures[0];
    
    if (nickometer) {
      const percentage = this.doNickometer(nickometer);
      return `${message.from}: '${nickometer}' is ${percentage}% lame.`;
    }
    
    return null;
  }

  doNickometer(nick) {
    this.score = 0;
    let _ = nick;

    // Special cases
    const specialCost = {
      '69': 500,
      'dea?th': 500,
      'dark': 400,
      'n[i1]ght': 300,
      'n[i1]te': 500,
      'fuck': 500,
      'sh[i1]t': 500,
      'coo[l1]': 500,
      'kew[l1]': 500,
      'lame': 500,
      'dood': 500,
      'dude': 500,
      '[l1](oo?|u)[sz]er': 500,
      '[l1]eet': 500,
      'e[l1]ite': 500,
      '[l1]ord': 500,
      'pron': 1000,
      'warez': 1000,
      'xx': 100,
      '\\[rkx]0': 1000,
      '\\0[rkx]': 1000
    };

    for (const [special, cost] of Object.entries(specialCost)) {
      let pattern = special;
      const raw = pattern.startsWith('\\');
      if (raw) pattern = pattern.substring(1);
      
      let checkNick = nick;
      if (!raw) {
        checkNick = checkNick.replace(/0/g, 'o').replace(/2/g, 'z').replace(/3/g, 'e')
          .replace(/4/g, 'a').replace(/5/g, 's').replace(/7/g, 't').replace(/\+/g, 't').replace(/8/g, 'b');
      }
      
      if (new RegExp(pattern, 'i').test(checkNick)) {
        this.punish(cost, `matched special case /${pattern}/`);
      }
    }

    // Allow Perl referencing
    _ = _.replace(/^\\([A-Za-z])/, '$1');
    
    // Keep safe from Pudge
    _ = _.replace(/\^(pudge)/i, '$1');
    
    // C-- ain't so bad
    if (_ === 'C--') _ = 'C';

    // Punish consecutive non-alphas
    _ = _.replace(/([^A-Za-z0-9]{2,})/g, (match) => {
      const consecutive = match.length;
      if (consecutive) {
        this.punish(this.slowPow(10, consecutive), `${consecutive} total consecutive non-alphas`);
      }
      return match;
    });

    // Remove balanced brackets and punish unmatched
    while (_.replace(/^([^()]*)(\(.*)(})([^()]*)$/, '$1$3$5') !== _ ||
           _.replace(/^([^{}]*)(\{)(.*)(})([^{}]*)$/, '$1$3$5') !== _ ||
           _.replace(/^([^\[\]]*)(\[)(.*)(])([^\[\]]*)$/, '$1$3$5') !== _) {
      _ = _.replace(/^([^()]*)(\(.*)(})([^()]*)$/, '$1$3$5')
           .replace(/^([^{}]*)(\{)(.*)(})([^{}]*)$/, '$1$3$5')
           .replace(/^([^\[\]]*)(\[)(.*)(])([^\[\]]*)$/, '$1$3$5');
    }
    
    const parentheses = (_.match(/[(){}[\]]/g) || []).length;
    if (parentheses) {
      this.punish(this.slowPow(10, parentheses), `${parentheses} unmatched ${parentheses === 1 ? 'parenthesis' : 'parentheses'}`);
    }

    // Punish k3wlt0k
    const k3wlt0kWeights = [5, 5, 2, 5, 2, 3, 1, 2, 2, 2];
    for (let digit = 0; digit <= 9; digit++) {
      const occurrences = (_.match(new RegExp(digit, 'g')) || []).length;
      if (occurrences) {
        this.punish(k3wlt0kWeights[digit] * occurrences * 30,
          `${occurrences} ${occurrences === 1 ? 'occurrence' : 'occurrences'} of ${digit}`);
      }
    }

    const origCase = _;
    
    // Handle case shifts
    _ = _.replace(/^([^A-Za-z]*[A-Z].*[a-z].*?)[_-]?([A-Z])/, (m, p1, p2) => p1 + p2.toLowerCase());
    _ = _.replace(/^([^A-Za-z]*)([A-Z])([a-z])/, (m, p1, p2, p3) => p1 + p2.toLowerCase() + p3);
    
    const caseShifts = this.caseShifts(origCase);
    if (caseShifts > 1 && /[A-Z]/.test(_)) {
      this.punish(this.slowPow(9, caseShifts), `${caseShifts} case ${caseShifts === 1 ? 'shift' : 'shifts'}`);
    }

    // Punish lame endings
    if (/[XZ][^a-zA-Z]*$/.test(origCase)) {
      this.punish(50, 'last alpha lame');
    }

    // Punish letter/number shifts
    const numberShifts = this.numberShifts(_);
    if (numberShifts > 1) {
      this.punish(this.slowPow(9, numberShifts), `${numberShifts} letter/number ${numberShifts === 1 ? 'shift' : 'shifts'}`);
    }

    // Punish extraneous caps
    const caps = (_.match(/[A-Z]/g) || []).length;
    if (caps) {
      this.punish(this.slowPow(7, caps), `${caps} extraneous caps`);
    }

    // Punish remaining symbols
    const remains = _.replace(/[a-zA-Z0-9]/g, '');
    const remainsLength = remains.length;
    if (remainsLength) {
      this.punish(50 * remainsLength + this.slowPow(9, remainsLength),
        `${remainsLength} extraneous ${remainsLength === 1 ? 'symbol' : 'symbols'}`);
    }

    // Calculate percentage
    const percentage = 100 * 
      (1 + Math.tanh((this.score - 400) / 400)) * 
      (1 - 1 / (1 + this.score / 5)) / 2;

    const digits = 2 * (2 - this.roundUp(Math.log(100 - percentage) / Math.log(10)));

    return percentage.toFixed(digits);
  }

  caseShifts(str) {
    let shifts = str.replace(/[^A-Za-z]/g, '');
    shifts = shifts.replace(/[A-Z]+/g, 'U');
    shifts = shifts.replace(/[a-z]+/g, 'l');
    return shifts.length - 1;
  }

  numberShifts(str) {
    let shifts = str.replace(/[^A-Za-z0-9]/g, '');
    shifts = shifts.replace(/[A-Za-z]+/g, 'l');
    shifts = shifts.replace(/[0-9]+/g, 'n');
    return shifts.length - 1;
  }

  slowPow(x, y) {
    return Math.pow(x, this.slowExponent(y));
  }

  slowExponent(x) {
    return 1.3 * x * (1 - Math.atan(x / 6) * 2 / Math.PI);
  }

  roundUp(float) {
    return Math.floor(float) + ((Math.floor(float) === float) ? 0 : 1);
  }

  punish(damage, reason) {
    if (!damage) return;
    this.score += damage;
  }

  help() {
    return 'Nickometer determines how lame a nick is using a complex algorithm. Usage: nickometer <nick>';
  }
}

Nickometer.prototype.parseMessage.isCommandRegEx = true;
Nickometer.prototype.parseMessage.pattern = /(.+)/;

export default Nickometer;
