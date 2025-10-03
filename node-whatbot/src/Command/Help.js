/**
 * Help.js - Help command
 * Matches Whatbot::Command::Help from Perl version
 */

import Command from './Command.js';

class Help extends Command {
  register() {
    this.commandPriority = 'Primary';
    this.requireDirect = false;
    
    // help or help <command>
    this.globalRegEx('^help ?(.*)?', 'parseMessage');
  }

  parseMessage(message, captures) {
    if (captures && captures[0] && captures[0].trim()) {
      const commandName = captures[0].trim();
      
      // Check if command exists
      const cmd = this.controller().commandShortName[commandName];
      if (cmd) {
        let helpText = cmd.help();
        // Support array or string
        const helpArray = Array.isArray(helpText) ? helpText : [helpText];
        
        const replies = [];
        for (const str of helpArray) {
          replies.push(message.reply({
            to: message.reply_to || message.from,
            text: str
          }));
        }
        return replies;
      } else {
        return message.reply({
          to: message.reply_to || message.from,
          text: `No such command: "${commandName}". ${this.available()}`
        });
      }
    } else {
      return `Whatbot is a modular, extensible, buzzword-compliant chat bot written in Node.js and tears. ${this.available()}`;
    }
  }

  available() {
    const modules = [];
    const cmdMap = this.controller().commandShortName;
    
    for (const [name, cmd] of Object.entries(cmdMap)) {
      if (name && name !== 'help') {
        const helpText = cmd.help();
        if (!helpText.match(/Help is not/)) {
          modules.push(name);
        }
      }
    }
    
    return 'Help is available for: ' + modules.join(', ');
  }

  help() {
    return 'Get help with "help" or "help <command>". Available commands vary by configuration.';
  }
}

export default Help;
