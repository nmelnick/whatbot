/**
 * Factoid.js - Factoid command (the heart of whatbot!)
 * Matches Whatbot::Command::Factoid from Perl version
 */

import Command from './Command.js';

class Factoid extends Command {
  constructor(config) {
    super(config);
    this.stfu = { subject: '', time: 0 };
    this.whoSaid = null;
    this.whenWas = null;
  }

  register() {
    this.commandPriority = 'Core';
    this.requireDirect = false;
    
    // what/who/wtf is <phrase>
    this.globalRegEx('^(wtf|what|who) (is|are) (.*)', 'whatIs');
    this.stopAfter('whatIs');
    
    // <phrase> is/are <definition>
    this.globalRegEx('^(.+?) (is|are) (.*)', 'assign');
    
    // forget <phrase>
    this.globalRegEx('^forget (.*)', 'forget');
    this.stopAfter('forget');
    
    // never remember <phrase>
    this.globalRegEx('^never remember (.*)', 'neverRemember');
    this.stopAfter('neverRemember');
    
    // shut up about / stfu about <phrase>
    this.globalRegEx('^(shut up|stfu) about (.*)', 'shutUp');
    this.stopAfter('shutUp');
    
    // random fact
    this.globalRegEx('^(random fact|jerk it)', 'randomFact');
    this.stopAfter('randomFact');
    
    // who said that
    this.globalRegEx('^(who said that)', 'whoSaidThat');
    this.stopAfter('whoSaidThat');
    
    // when was that
    this.globalRegEx('^(when was that)', 'whenWasThat');
    this.stopAfter('whenWasThat');
  }

  whatIs(message, captures) {
    return this.retrieve(captures[2], message, true);
  }

  assign(message, captures) {
    const subject = captures[0];
    const assigner = captures[1];
    const description = captures[2];
    
    // Don't capture "what is" questions
    if (subject.match(/^(wtf|what|who)$/)) {
      return null;
    }
    
    const isPlural = assigner.match(/are/i) ? 1 : 0;
    
    // Remove trailing punctuation
    let cleanDesc = description.replace(/[\. ]$/g, '');
    
    // If not direct, only grab one sentence (flyby capture)
    if (!message.is_direct) {
      cleanDesc = cleanDesc.replace(/[\.'] .*$/g, '');
    }
    
    // Handle "you" reference
    let cleanSubject = subject;
    if (message.is_direct && subject.toLowerCase() === 'you') {
      cleanSubject = message.me;
    }
    
    // Store factoid (handles "or" syntax internally)
    const factoids = cleanDesc.split(/ or /);
    for (const factoid of factoids) {
      this.model('factoid').factoid(cleanSubject, factoid, message.from, isPlural);
    }
    
    if (message.is_direct) {
      return `OK, ${message.from}.`;
    }
    
    return null;
  }

  forget(message, captures) {
    const result = this.model('factoid').forget(captures[0]);
    if (result) {
      return `I forgot "${captures[0]}", ${message.from}.`;
    }
    return null;
  }

  neverRemember(message, captures) {
    this.model('factoid').forget(captures[0]);
    this.model('factoid').ignore(captures[0], true);
    return `I will permanently forget "${captures[0]}", ${message.from}.`;
  }

  shutUp(message, captures) {
    const subject = captures[1];
    
    // Rate limit - don't respond if same subject within 45 seconds
    if (this.stfu.subject === subject && (Math.floor(Date.now() / 1000) - this.stfu.time) < 45) {
      return null;
    }
    
    const silent = this.model('factoid').toggleSilence(subject);
    
    if (silent !== null) {
      this.stfu = {
        subject: subject,
        time: Math.floor(Date.now() / 1000)
      };
      
      if (silent == 1) {
        return `I will shut up about "${subject}", ${message.from}.`;
      } else {
        return `I will keep talking about "${subject}", ${message.from}.`;
      }
    } else {
      return `I do not have any facts for "${subject}", ${message.from}.`;
    }
  }

  randomFact(message) {
    const count = this.model('factoid').count();
    if (count === 0) {
      return 'No factoids stored yet.';
    }
    
    let factoidId = Math.floor(Math.random() * count) + 1;
    if (factoidId < 1) factoidId = 1;
    
    const factoid = this.model('factoid').find(factoidId);
    if (!factoid) {
      return 'Could not find a random factoid.';
    }
    
    // Get users who contributed
    const descriptions = this.model('factoid').tableDescription.search({ 
      factoid_id: factoidId 
    });
    
    const users = descriptions.map(d => d.user);
    this.whoSaid = users.length === 1 ? users[0] : users.join(', ');
    this.whenWas = users.length === 1 ? factoid.updated : 0;
    
    return this.retrieve(factoid.subject, message);
  }

  whoSaidThat(message) {
    if (this.whoSaid) {
      if (message.from === this.whoSaid) {
        return `${message.from}: it was YOU!`;
      } else {
        return `${message.from}: ${this.whoSaid}`;
      }
    }
    return null;
  }

  whenWasThat(message) {
    if (this.whenWas) {
      const date = new Date(this.whenWas * 1000);
      const ymd = date.toISOString().split('T')[0];
      const hms = date.toTimeString().split(' ')[0];
      return `Looks like it was on ${ymd} at ${hms}.`;
    }
    return 'No idea.';
  }

  retrieve(subject, message, direct = false) {
    let everything = false;
    subject = subject.replace(/[\?\!\. ]*$/, '');
    
    if (subject.match(/^everything for/)) {
      subject = subject.replace(/^everything for +/, '');
      everything = true;
    }
    
    const factoidPackage = this.model('factoid').factoid(subject);
    
    // Check if factoid exists and if it should respond
    if (!factoidPackage) {
      if (direct && message.is_direct) {
        return `I have no idea what '${subject}' could be, ${message.from}.`;
      }
      return null;
    }
    
    const factoid = factoidPackage.factoid;
    
    // Check silent mode
    if (factoid.silent && factoid.silent == 1 && !direct) {
      return null;
    }
    
    let facts;
    if (factoid.isOr && factoid.isOr == 1) {
      // Pick random fact if is_or
      const randomIndex = Math.floor(Math.random() * factoidPackage.facts.length);
      facts = [factoidPackage.facts[randomIndex]];
    } else {
      facts = factoidPackage.facts;
    }
    
    // Process <who> placeholder
    for (let i = 0; i < facts.length; i++) {
      if (facts[i].match(/<who>/)) {
        facts[i] = facts[i].replace(/<who>/g, message.from);
      }
    }
    
    // Store who said it for "who said that"
    if (facts.length === 1) {
      this.whoSaid = factoidPackage.user || null;
    }
    
    // Handle <reply> prefix
    if (facts.length === 1 && facts[0].match(/^<reply>/)) {
      return facts[0].replace(/^<reply> +/, '');
    }
    
    // Build response
    let subj = subject;
    if (subject.toLowerCase() === message.from.toLowerCase()) {
      subj = 'you';
    }
    
    if (message.is_direct) {
      subj = `${message.from}, ${subj}`;
    }
    
    let factoidData = facts.join(' or ');
    
    // Summarize if too long (over 400 chars)
    if (!everything && factoidData.length > 400) {
      factoidData = 'summarized as ';
      const usedFacts = {};
      let tries = 0;
      let bigTries = 0;
      
      while (factoidData.length < 380 && bigTries < 5 && tries < 10) {
        const factNum = Math.floor(Math.random() * facts.length);
        
        if (usedFacts[factNum]) {
          tries++;
          continue;
        }
        
        usedFacts[factNum] = true;
        
        if (factoidData.length + facts[factNum].length > 410) {
          bigTries++;
          continue;
        }
        
        if (Object.keys(usedFacts).length > 1) {
          factoidData += ' or ';
        }
        factoidData += facts[factNum];
      }
    }
    
    const verb = factoid.isPlural ? 'are' : 'is';
    return `${subj} ${verb} ${factoidData}`;
  }

  help() {
    return 'Store facts with "<subject> is <definition>". Retrieve with "what is <subject>". Use "forget <subject>" to delete. Add "or" between definitions for alternatives. Use "<reply>" prefix for direct responses. Silence with "shut up about <subject>".';
  }
}

export default Factoid;
