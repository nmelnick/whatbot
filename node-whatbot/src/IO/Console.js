/**
 * Console.js - Console/terminal IO for whatbot
 * Matches Whatbot::IO::Console from Perl version
 */

import readline from 'readline';
import IO from './IO.js';

class Console extends IO {
  constructor(config) {
    super(config);
    this.name('Console');
    this.me('console_user');
    this.rl = null;
  }

  async connect() {
    this.log().write('Starting console interface...');
    
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      prompt: '> '
    });

    this.rl.on('line', async (line) => {
      if (line.trim()) {
        const message = this.getNewMessage({
          from: 'console_user',
          to: 'console',
          content: line.trim()
        });
        
        await this.eventMessage(message);
      }
      this.rl.prompt();
    });

    this.rl.on('close', () => {
      this.log().write('Console interface closed.');
      process.exit(0);
    });

    this.log().write('Console interface ready. Type messages below:');
    this.rl.prompt();
  }

  async disconnect() {
    if (this.rl) {
      this.rl.close();
    }
  }

  async deliverMessage(message) {
    // Don't echo back messages from console_user
    if (message.from === this.me()) {
      console.log(`${this.me()}: ${message.content}`);
    }
    // Pause/resume to prevent prompt interference
    this.rl.pause();
    setTimeout(() => this.rl.resume(), 10);
  }
}

export default Console;
