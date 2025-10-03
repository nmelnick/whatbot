import Command from './Command.js';
import net from 'net';

class Excuse extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;
  }

  async parseMessage(message) {
    const config = this.my_config || {};
    const host = config.host || 'bob.bob.bofh.org';
    const port = config.port || 666;

    try {
      const excuse = await this._getExcuse(host, port);
      return `${message.from}: ${excuse}`;
    } catch (error) {
      return 'The excuse server is down.';
    }
  }

  _getExcuse(host, port) {
    return new Promise((resolve, reject) => {
      const client = new net.Socket();
      let data = '';

      client.setTimeout(5000);

      client.on('data', (chunk) => {
        data += chunk.toString();
        
        if (data.includes('Your excuse is:')) {
          const lines = data.split('\n');
          for (const line of lines) {
            if (line.includes('Your excuse is')) {
              client.destroy();
              resolve(line.trim());
              return;
            }
          }
        }
      });

      client.on('timeout', () => {
        client.destroy();
        reject(new Error('Connection timeout'));
      });

      client.on('error', (err) => {
        reject(err);
      });

      client.connect(port, host);
    });
  }

  help() {
    return 'Excuse uses an excuse server to deliver a random response to your ' +
           'inquiry. Even better, the inquiry is optional.';
  }
}

Excuse.prototype.parseMessage.isCommandRegEx = true;
Excuse.prototype.parseMessage.pattern = /(.*)/;

export default Excuse;
