/**
 * Ping.js - Simple test command
 */

import Command from './Command.js';

class Ping extends Command {
  register() {
    this.commandPriority = 'Extension';
    this.requireDirect = false;
    
    // Respond to "ping"
    this.globalRegEx('^ping$', 'ping');
  }

  ping(message) {
    return 'pong';
  }

  help() {
    return 'Responds to "ping" with "pong"';
  }
}

export default Ping;
