import Command from './Command.js';

class FactoidListener extends Command {
  register() {
    this.priority = 'Last';
    this.requireDirect = false;

    this.globalRegEx(/^(.+)$/, 'listener');
  }

  async listener(message, captures) {
    const factoidCommand = this.controller.commands.find(
      cmd => cmd.name === 'factoid'
    );
    
    if (factoidCommand && factoidCommand.retrieve) {
      return await factoidCommand.retrieve(captures[0], message);
    }

    return null;
  }

  help() {
    return 'FactoidListener passively listens for factoid triggers.';
  }
}

export default FactoidListener;
