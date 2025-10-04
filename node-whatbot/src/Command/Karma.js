/**
 * Karma.js - Karma tracking command
 * Matches Whatbot::Command::Karma from Perl version
 */

import Command from './Command.js';

class Karma extends Command {
  register() {
    this.commandPriority = 'Core';
    this.requireDirect = false;
    
    // Parse karma operations (++ / --)
    this.globalRegEx('[\\+\\-]{2}', 'parseMessage');
    
    // karma <phrase> - check karma
    this.commandRegEx('(.*)', 'karma');
    
    // karma info <phrase> - extended info
    this.command('info');
    
    // what/who does <user> like/hate
    this.globalRegEx('(what|who) does (\\w+) (like|hate)', 'whatDoes');
  }

  parseMessage(message) {
    const content = message.content;
    
    // Parse (phrase)++ or (phrase)--
    const multiWordRegex = /\(([^\-\+]+?)\)([\+\-]{2})/g;
    let match;
    while ((match = multiWordRegex.exec(content)) !== null) {
      const phrase = match[1];
      const op = match[2];
      this.parseOperator(phrase, op, message.from);
    }
    
    // Parse word++ or word--
    const singleWordRegex = /([^ \-\+\)\(]+)([\+\-]{2})/g;
    while ((match = singleWordRegex.exec(content)) !== null) {
      const word = match[1];
      const op = match[2];
      this.parseOperator(word, op, message.from);
    }
    
    return null; // Silent operation
  }

  parseOperator(subject, operator, from) {
    // Clean up subject
    subject = subject.replace(/\++$/, '');
    subject = subject.replace(/\-+$/, '');
    subject = subject.toLowerCase();
    
    // Can't karma yourself
    if (subject === from.toLowerCase()) {
      return;
    }
    
    // Use canonical username
    subject = this.model('useralias').canonicalUser(subject);
    
    if (operator === '++') {
      this.model('karma').increment(subject, from);
    } else if (operator === '--') {
      this.model('karma').decrement(subject, from);
    }
    // +- or -+ is ignored
  }

  karma(message, captures) {
    if (!captures || !captures[0]) {
      return null;
    }
    
    const phrase = captures[0].trim();
    
    // Hack to pass through if requesting info
    if (phrase.match(/^info/)) {
      return null;
    }
    
    const user = this.model('useralias').canonicalUser(phrase);
    const karma = this.model('karma').get(user);
    
    if (karma && karma != 0) {
      const suffix = (phrase !== user) ? ` (as ${user})` : '';
      return `${phrase}${suffix} has a karma of ${karma}`;
    } else {
      return `${phrase} has no karma`;
    }
  }

  info(message, captures) {
    if (!captures || !captures[0]) {
      return null;
    }
    
    const phrase = captures.join(' ').toLowerCase();
    const user = this.model('useralias').canonicalUser(phrase);
    const karmaInfo = this.model('karma').getExtended(user);
    
    if (karmaInfo && (karmaInfo.Increments != 0 || karmaInfo.Decrements != 0)) {
      const total = karmaInfo.Increments - karmaInfo.Decrements;
      const totalVotes = karmaInfo.Increments + karmaInfo.Decrements;
      const rocks = (100 * (karmaInfo.Increments / totalVotes)).toFixed(1);
      const sucks = (100 * (karmaInfo.Decrements / totalVotes)).toFixed(1);
      
      const suffix = (phrase !== user) ? ` (as ${user})` : '';
      const rocksOrSucks = rocks > sucks ? `${rocks}% rocks` : `${sucks}% sucks`;
      const lastOp = karmaInfo.Last[1] == 1 ? '++' : '--';
      
      return `${phrase}${suffix} has had ${karmaInfo.Increments} increments and ${karmaInfo.Decrements} decrements, for a total of ${total}. ${phrase} ${rocksOrSucks}. Last change was by ${karmaInfo.Last[0]}, who gave it a ${lastOp}.`;
    } else {
      return `${phrase} has no karma`;
    }
  }

  whatDoes(message, captures) {
    const who = captures[1];
    const verb = captures[2];
    const nick = this.model('useralias').canonicalUser(message.from);
    
    let karmas;
    if (verb === 'like') {
      karmas = this.model('karma').topN(who, 10);
    } else {
      karmas = this.model('karma').bottomN(who, 10);
    }
    
    if (!karmas || karmas.length === 0) {
      return `${nick}: I don't know what ${who} ${verb}s.`;
    }
    
    // Filter to only liked or hated things
    karmas = karmas.filter(k => {
      return verb === 'like' ? (k.sum > 0) : (k.sum < 0);
    });
    
    const results = karmas.map(k => `${k.subject} (${k.sum})`);
    
    return `${who} ${verb}s: ${results.join(', ')}`;
  }

  help() {
    return 'Karma tracking: Use "thing++" to increment, "thing--" to decrement. Check with "karma <thing>" or "karma info <thing>". Ask "what does <user> like/hate" to see their karma activity.';
  }
}

export default Karma;
