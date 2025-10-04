/**
 * Seen.js - Seen tracking command
 * Matches Whatbot::Command::Seen from Perl version
 */

import Command from './Command.js';

class Seen extends Command {
  register() {
    this.commandPriority = 'Core';
    this.requireDirect = false;
    
    // Monitor all messages to track seen
    this.monitor('storeUser');
    
    // seen <user>
    this.commandRegEx('(.+)', 'seen');
  }

  storeUser(message) {
    if (message.invisible) {
      return null;
    }
    
    this.model('seen').seen(message.from.toLowerCase(), message.content);
    return null;
  }

  seen(message, captures) {
    if (!captures || !captures[0]) {
      return null;
    }
    
    let user = captures[0];
    user = user.replace(/[\?\!\.]+$/, '');
    
    let users = [user];
    const aliases = this.model('useralias').relatedUsers(user.toLowerCase());
    if (aliases && aliases.length > 0) {
      users.push(...aliases);
    }

    let last = null;
    for (const userAlias of users) {
      const ret = this.model('seen').seen(userAlias.toLowerCase());
      if (ret && ret.user) {
        if (!last) {
          last = ret;
        } else if (ret.timestamp > last.timestamp) {
          last = ret;
        }
      }
    }

    if (last) {
      const date = new Date(last.timestamp * 1000);
      const dateStr = date.toISOString().split('T')[0];
      const timeStr = date.toTimeString().split(' ')[0];
      const asClause = last.user !== user.toLowerCase() ? ` as ${last.user}` : '';
      
      return `${user} was last seen${asClause} on ${dateStr} at ${timeStr} UTC saying, "${last.message}".`;
    } else {
      return `I have not seen ${user} yet.`;
    }
  }

  help() {
    return 'Track when users were last seen. Use "seen <user>" to check. All messages are automatically tracked.';
  }
}

export default Seen;
