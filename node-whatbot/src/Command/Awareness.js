import Command from './Command.js';

class Awareness extends Command {
  register() {
    this.priority = 'Primary';
    this.requireDirect = false;

    this.monitor('message');
    this.globalRegEx(/^show last message$/i, 'lastMessage');
  }

  async message(messageRef) {
    const me = messageRef.me;
    
    if (new RegExp(`^${me}[\\?\\!\\.]?$`, 'i').test(messageRef.content)) {
      return 'what';
    }

    const greetings = [
      'hey',
      'sup',
      "what's up",
      'yo',
      'word',
      'hi',
      'hello',
      'greetings',
      'allo'
    ];

    if (messageRef.isDirect && 
        /^(hey|hi|hello|word|sup|morning|good morning)[\?\!\. ]*?$/i.test(messageRef.content)) {
      const greeting = greetings[Math.floor(Math.random() * greetings.length)];
      return `${greeting}, ${this.tagUser(messageRef.from)}.`;
    }

    return null;
  }

  async lastMessage(message) {
    return this.parent?.lastMessage || 'No last message available.';
  }

  help() {
    return [
      'Awareness provides context-aware responses.',
      'Responds to greetings and name mentions.'
    ];
  }
}

export default Awareness;
