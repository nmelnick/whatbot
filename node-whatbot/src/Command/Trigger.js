import Command from './Command.js';

class Trigger extends Command {
  constructor(options) {
    super(options);
    this.triggers = {};
  }

  register() {
    this.priority = 'Core';
    this.requireDirect = false;

    this.command('set');
    this.command('unset');
    this.command('stats');
    this.command('find');
    this.globalRegEx(/(.+)/, 'listener');
    this.event('enter', 'listenEnter');
    this.event('leave', 'listenLeave');
    this.event('user_change', 'listenUserChange');

    // Load triggers on first use
    this._triggersLoaded = false;
  }

  async _loadTriggers() {
    if (this._triggersLoaded) return;
    
    const soup = this.model('Soup');
    if (soup) {
      this.triggers = await soup.getHashref('Trigger') || {};
    }
    this._triggersLoaded = true;
  }

  async unset(message, captures) {
    await this._loadTriggers();
    
    let unset = captures.join(' ');
    unset = unset.replace(/^\//, '').replace(/\/$/, '');

    const soup = this.model('Soup');
    const existing = await soup.get(unset, 'Trigger');
    
    if (existing) {
      await soup.clear(unset, 'Trigger');
      this._triggersLoaded = false; // Force reload on next check
      await this._loadTriggers();
      return 'Removed trigger.';
    }
    
    return 'I could not find that trigger.';
  }

  async set(message, captures) {
    await this._loadTriggers();
    let trigger, escape = false, hasTrigger = false, response;
    const full = captures.join(' ');

    // Event triggers
    if (/^event:(\w+) (.*)$/.test(full)) {
      const match = full.match(/^event:(\w+) (.*)$/);
      const event = match[1];
      response = match[2];

      if (/^(enter|leave|user_change)$/.test(event)) {
        if (/^\((.*?)\) /.test(response)) {
          const params = response.match(/^\((.*?)\) /)[1];
          response = response.replace(/^\(.*?\) /, '');
          if (params.includes('=')) {
            trigger = `event:${event} (${params})`;
          } else {
            trigger = `event:${event}`;
          }
        } else {
          trigger = `event:${event}`;
        }
        hasTrigger = true;
      } else {
        return `No idea what the "${event}" event is. Try enter, leave, or user_change.`;
      }
    } else {
      // Regex triggers
      const setLine = full.split('');
      if (setLine.length && setLine[0] === '/') {
        setLine.shift();
        trigger = '';
        
        while (setLine.length) {
          const char = setLine.shift();
          
          if (char === '/') {
            if (escape) {
              trigger += '\\/';
              continue;
            } else {
              if (setLine[0] !== ' ') {
                break;
              }
              hasTrigger = true;
              break;
            }
          } else if (char === '\\') {
            escape = true;
            continue;
          } else {
            if (escape) trigger += '\\';
            trigger += char;
          }
          escape = false;
        }
        
        response = setLine.join('').replace(/^\s+/, '');
      }
    }

    if (hasTrigger) {
      const soup = this.model('Soup');
      const existing = await soup.get(trigger, 'Trigger');
      
      if (existing) {
        return `A trigger already exists for "${trigger}".`;
      }
      
      await soup.set(trigger, response, 'Trigger');
      this._triggersLoaded = false; // Force reload on next check
      await this._loadTriggers();
      return 'Trigger set.';
    }

    return 'Invalid trigger: You must start with a regular expression inside ' +
           'two forward slashes or an event type, followed by the response.';
  }

  async stats(message) {
    await this._loadTriggers();
    const count = Object.keys(this.triggers).length;
    const plural = count === 1 ? '' : 's';
    const verb = count === 1 ? 'is' : 'are';
    return `There ${verb} ${count} trigger${plural} set.`;
  }

  async find(message, captures) {
    await this._loadTriggers();
    if (!captures || captures.length === 0) return null;
    
    const search = captures[0];
    const responses = [];
    
    for (const [trigger, response] of Object.entries(this.triggers)) {
      if (responses.length > 2) {
        responses.push('There are more, maybe you should make your search more specific.');
        break;
      }
      
      if (response.includes(search)) {
        responses.push(`Found /${trigger}/ => ${response}`);
      }
    }
    
    return responses.length ? responses : null;
  }

  async listener(message) {
    await this._loadTriggers();
    const responses = [];
    
    for (const [trigger, response] of Object.entries(this.triggers)) {
      if (trigger.startsWith('event')) continue;
      
      try {
        const regex = new RegExp(trigger);
        const captures = message.content.match(regex);
        
        if (captures) {
          let processedResponse = response;
          
          // Handle <reply>
          if (processedResponse.includes('<reply>')) {
            processedResponse = processedResponse.replace(/^<reply> +/, '');
          }
          
          // Handle <who>
          if (processedResponse.includes('<who>')) {
            processedResponse = processedResponse.replace(/<who>/g, message.from);
          }
          
          // Replace captures
          if (captures.length > 1) {
            for (let i = 1; i < captures.length; i++) {
              const capture = captures[i];
              processedResponse = processedResponse.replace(new RegExp(`\\$${i}`, 'g'), capture);
            }
          }
          
          responses.push(processedResponse);
        }
      } catch (e) {
        // Invalid regex, skip
      }
    }
    
    return responses.length ? responses : null;
  }

  async listenEnter(target, eventInfo) {
    await this._loadTriggers();
    return this._processEventTriggers('enter', eventInfo);
  }

  async listenLeave(target, eventInfo) {
    await this._loadTriggers();
    return this._processEventTriggers('leave', eventInfo);
  }

  async listenUserChange(target, eventInfo) {
    await this._loadTriggers();
    return this._processEventTriggers('user_change', eventInfo);
  }

  _processEventTriggers(eventType, eventInfo) {
    const responses = [];
    const triggers = this._getTriggersForEvent(eventType);
    const nick = eventInfo.nick;
    
    for (const trigger of triggers) {
      const paramMatch = trigger.match(/\((.*?)\)$/);
      
      if (paramMatch) {
        const triggerInfo = paramMatch[1];
        const mapping = {};
        triggerInfo.split(';').forEach(pair => {
          const [key, value] = pair.split('=');
          mapping[key] = value;
        });
        
        if (mapping.user && mapping.user.toLowerCase() !== nick.toLowerCase()) {
          continue;
        }
      }
      
      let response = this.triggers[trigger];
      response = response.replace(/\{user\}/g, nick);
      responses.push(response);
    }
    
    return responses.length ? responses : null;
  }

  _getTriggersForEvent(eventType) {
    const triggers = [];
    for (const trigger of Object.keys(this.triggers)) {
      if (trigger.startsWith(`event:${eventType}`)) {
        triggers.push(trigger);
      }
    }
    return triggers;
  }

  help() {
    return [
      'Trigger will listen for snippets within incoming messages and respond ' +
      'accordingly. So, if you want the bot to scream every time someone ' +
      'says the magic word, enter "trigger set /magic word/ /me screams!".',
      ' * "set /regex/ response" -- set a trigger',
      ' * unset /regex/ -- unset a trigger',
      ' * stats -- show how many triggers are set',
      ' * find [partial response] -- find a trigger based on the response'
    ];
  }
}

export default Trigger;
