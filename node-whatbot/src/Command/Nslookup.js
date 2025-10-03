import Command from './Command.js';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

class Nslookup extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;
  }

  async parseMessage(message, captures) {
    if (!captures || !captures[0]) return null;

    const host = captures[0];
    
    try {
      const { stdout } = await execAsync(`host ${host}`);
      
      if (/has address ([\d\.]+)/.test(stdout)) {
        const ip = stdout.match(/has address ([\d\.]+)/)[1];
        return `${host} is at ${ip}`;
      } else if (/not found/.test(stdout)) {
        return `I can't find ${host}`;
      }
    } catch (error) {
      return `I can't find ${host}`;
    }
    
    return null;
  }

  help() {
    return 'Nslookup uses host command to resolve hostnames to IP addresses.';
  }
}

Nslookup.prototype.parseMessage.isCommandRegEx = true;
Nslookup.prototype.parseMessage.pattern = /(.+)/;

export default Nslookup;
