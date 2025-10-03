import Command from './Command.js';

class Tell extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.commandRegEx(/^(.*)$/, 'requestTell', { stopAfter: true });
    this.event('enter', 'doTell');
    this.event('user_change', 'doTell');
    this.globalRegEx(/^what are you telling ([^\s\?]+)/i, 'queryTell');
  }

  async requestTell(message, captures) {
    if (!captures || !captures[0]) return null;

    const parts = captures[0].split(/\s+/);
    const username = parts.shift();
    let tell = parts.join(' ');

    tell = tell.replace(/\[\[\]]/g, '');
    tell = tell.replace(/\]/g, '');
    tell = tell.replace(/^that /, '');
    tell = tell.replace(/^s?he is/i, 'you are');
    tell = tell.replace(/^s?he/i, 'you');
    tell = tell.replace(/^you ([a-z]+?)s$/, 'you $1');

    tell = message.from + '|[' + tell;

    const storedUsername = message.to + '|' + username.toLowerCase();
    const previous = await this.model('Soup').get(storedUsername, 'Tell');
    
    if (previous) {
      const tells = previous.split('|]');
      for (const existingTell of tells) {
        if (existingTell === tell) {
          return `You are already telling that to ${username}, ${message.from}.`;
        }
      }
      tell = previous + '|]' + tell;
    }
    
    await this.model('Soup').set(storedUsername, tell, 'Tell');
    return `OK, ${message.from}.`;
  }

  async doTell(target, eventInfo) {
    const [io, context] = target.split(':');
    const user = eventInfo.nick;
    const searchUser = user.toLowerCase();
    const query = context + '|' + searchUser;
    
    const response = await this.model('Soup').get(query, 'Tell');
    if (response) {
      const replies = [];
      const responseArr = response.split('|]');
      
      for (const tell of responseArr) {
        const [from, toTell] = tell.split('|[');
        const punctuation = /[\.\?!]$/.test(toTell) ? '' : '.';
        replies.push(`${user}, ${from} wants you to know ${toTell}${punctuation}`);
      }
      
      await this.model('Soup').clear(query, 'Tell');
      return replies;
    }
    
    return null;
  }

  async queryTell(message, captures) {
    const searchUser = captures[0].toLowerCase();
    if (!searchUser) return null;

    const response = await this.model('Soup').get(
      message.to + '|' + searchUser,
      'Tell'
    );
    
    if (response) {
      const replies = [];
      const responseArr = response.split('|]');
      
      for (const tell of responseArr) {
        const [from, toTell] = tell.split('|[');
        const punctuation = /[\.\?!]$/.test(toTell) ? '' : '.';
        replies.push(`Telling: ${from} wants ${captures[0]} to know "${toTell}${punctuation}"`);
      }
      
      return replies;
    } else {
      return `Nothing, ${message.from}.`;
    }
  }

  help() {
    return [
      'Tell allows you to leave a message for someone who is not currently in the channel.',
      'Usage: tell <username> <message>',
      'The bot will deliver the message when the user enters the channel or changes their nickname.',
      'To check what messages are pending for a user: "what are you telling <username>"'
    ];
  }
}

export default Tell;
