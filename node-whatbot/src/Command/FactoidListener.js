import Command from './Command.js';

class FactoidListener extends Command {
  register() {
    this.priority = 'Last';
    this.requireDirect = false;

    this.globalRegEx(/^(.+)$/, 'listener');
  }

  async listener(message, captures) {
    const controller = this.controller();
    if (!controller || !controller.commandShortName) {
      return null;
    }
    
    const factoidCommand = controller.commandShortName['factoid'];
    
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
