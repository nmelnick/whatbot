import Command from './Command.js';

class Math extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.globalRegEx(/^\(*\-?\d[\d\.]*[\+\-\*\/][\d\(\)\+\-\*\/\.]*\d\)*$/, 'freeForm');
    this.globalRegEx(/^\s*\d+\s*[\+\-\*\/]\s*\d+$/, 'simpleCalc');
    this.globalRegEx(/^calc (.*)/, 'parseMessage');
    this.globalRegEx(/^rand (.*)/, 'rand');
    this.globalRegEx(/^roll ([0-9]+)/, 'roll');
  }

  async freeForm(message) {
    return this.parseMessage(message, [message.content]);
  }

  async simpleCalc(message) {
    return this.parseMessage(message, [message.content]);
  }

  async parseMessage(message, captures) {
    const expression = captures[0];
    if (!expression) return null;

    const result = this._parse(expression);
    return `${message.from}: ${result}`;
  }

  async rand(message, captures) {
    const list = captures[0];
    if (!list) return null;

    const choices = list.split(' ');
    const choice = choices[globalThis.Math.floor(globalThis.Math.random() * choices.length)];
    
    return `${message.from}: ${choice}`;
  }

  async roll(message, captures) {
    const sides = parseInt(captures[0]);
    if (!sides) return null;

    const result = globalThis.Math.floor(globalThis.Math.random() * sides) + 1;
    return `${message.from}: ${result}`;
  }

  _parse(expression) {
    const lines = expression.split(';');
    let result = null;

    for (const line of lines) {
      try {
        const sanitized = this._sanitize(line);
        if (!sanitized) {
          return 'Error: Invalid expression';
        }

        result = eval(sanitized);
      } catch (err) {
        return `Error: ${err.message}`;
      }
    }

    if (typeof result === 'number') {
      if (Number.isInteger(result)) {
        return this._formatNumber(result);
      } else {
        return result.toFixed(2);
      }
    }

    return result !== null ? result.toString() : 'Error: No result';
  }

  _sanitize(expr) {
    expr = expr.trim();
    
    const allowedChars = /^[\d\s\+\-\*\/\(\)\.\,]+$/;
    if (!allowedChars.test(expr)) {
      return null;
    }

    expr = expr.replace(/,/g, '');
    
    return expr;
  }

  _formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  help() {
    return [
      'Math provides calculator functionality.',
      'Usage: calc <expression> - Evaluate a mathematical expression',
      'Usage: rand <item1> <item2> ... - Pick a random item from the list',
      'Usage: roll <sides> - Roll a dice with the specified number of sides',
      'You can also just type simple math expressions like "2 + 2" or "10 * 5"'
    ];
  }
}

export default Math;
