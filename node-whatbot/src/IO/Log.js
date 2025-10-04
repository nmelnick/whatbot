import IO from './IO.js';
import fs from 'fs';
import readline from 'readline';

class Log extends IO {
  constructor(config) {
    super(config);
    
    this.name = 'Log';
    this.me = this.myConfig.me;
    this.fileHandle = null;
    this.lineCount = 0;
    this.currentLine = 0;
    this.rl = null;
  }

  async connect() {
    const filepath = this.myConfig.filepath;
    this.log.write(`Opening ${filepath}`);
    
    this.lineCount = await this._countLines(filepath);
    
    this.fileHandle = fs.createReadStream(filepath);
    this.rl = readline.createInterface({
      input: this.fileHandle,
      crlfDelay: Infinity
    });

    this.rl.on('line', (line) => {
      this.currentLine++;
      this.parseLine(line);
      
      if (this.currentLine % 1000 === 0) {
        console.log(`Progress: ${this.currentLine}/${this.lineCount}`);
      }
    });

    this.rl.on('close', () => {
      console.log(`Finished processing ${this.currentLine} lines`);
      this.parent?.stop();
    });
  }

  async disconnect() {
    this.log.write(`Closing ${this.myConfig.filepath}`);
    if (this.rl) {
      this.rl.close();
    }
    if (this.fileHandle) {
      this.fileHandle.close();
    }
  }

  deliverMessage(message) {
    // Log IO doesn't deliver messages
  }

  parseLine(line) {
    // Override in subclasses
  }

  async _countLines(filepath) {
    return new Promise((resolve, reject) => {
      let lineCount = 0;
      const rs = fs.createReadStream(filepath);
      rs.on('data', (chunk) => {
        for (let i = 0; i < chunk.length; i++) {
          if (chunk[i] === 10) lineCount++;
        }
      });
      rs.on('end', () => resolve(lineCount));
      rs.on('error', reject);
    });
  }
}

export default Log;
