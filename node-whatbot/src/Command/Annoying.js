import Command from './Command.js';

class Annoying extends Command {
  constructor(options) {
    super(options);
    this.beAnnoying = false;
  }

  register() {
    this.priority = 'Last';
    this.requireDirect = false;
    
    this.globalRegEx(/^(don'?t )?be annoying[.!]?$/i, 'toggle');
    this.globalRegEx(/./, 'respond');
  }

  toggle(message, captures) {
    this.beAnnoying = !this.beAnnoying;
    return `OK, I am ${this.beAnnoying ? '' : 'no longer as '}annoying.`;
  }

  respond(message) {
    if (!this.beAnnoying || /^(don'?t )?be annoying[.!]?$/i.test(message.content)) {
      return null;
    }
    
    return this.annoying(message.content);
  }

  annoying(content) {
    // Simple LOLCAT-style transformation
    let result = content;
    
    // Basic LOLCAT substitutions
    const substitutions = {
      'you': 'u',
      'your': 'ur',
      'you\'re': 'ur',
      'the': 'teh',
      'can': 'canz',
      'has': 'haz',
      'have': 'haz',
      'my': 'mah',
      'me': 'meh',
      'please': 'plz',
      'thanks': 'kthx',
      'okay': 'k',
      'ok': 'k',
      'what': 'wut',
      'with': 'wif',
      'this': 'dis',
      'that': 'dat',
      'very': 'vry',
      'really': 'rly',
      'are': 'r',
      'is': 'iz'
    };

    for (const [find, replace] of Object.entries(substitutions)) {
      const regex = new RegExp(`\\b${find}\\b`, 'gi');
      result = result.replace(regex, replace);
    }

    // Add some random capitalization
    if (Math.random() > 0.5) {
      result = result.split('').map((char, i) => 
        i % 2 === 0 ? char.toUpperCase() : char.toLowerCase()
      ).join('');
    }

    return result;
  }

  help() {
    return 'Annoying parrots back any line in LOLCAT speak. Toggle with "be annoying" or "don\'t be annoying".';
  }
}

export default Annoying;
