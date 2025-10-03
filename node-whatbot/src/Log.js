/**
 * Log.js - Logger for whatbot
 * Matches Whatbot::Log from Perl version
 */

import fs from 'fs';
import path from 'path';

class Log {
  constructor({ log_directory }) {
    this.logDirectory = log_directory;
    this._name = 'whatbot';

    // Create log directory if it doesn't exist
    if (!fs.existsSync(this.logDirectory)) {
      fs.mkdirSync(this.logDirectory, { recursive: true });
    }

    this.logFile = path.join(this.logDirectory, 'whatbot.log');
  }

  get log_directory() {
    return this.logDirectory;
  }

  name(newName) {
    if (newName) {
      this._name = newName;
    }
    return this._name;
  }

  write(message) {
    const timestamp = new Date().toISOString();
    const prefix = this._name ? `[${this._name}] ` : '';
    const logMessage = `${timestamp} ${prefix}${message}\n`;
    
    // Write to console
    console.log(`${prefix}${message}`);
    
    // Write to file
    fs.appendFileSync(this.logFile, logMessage);
  }

  error(message) {
    const timestamp = new Date().toISOString();
    const prefix = this._name ? `[${this._name}] ` : '';
    const logMessage = `${timestamp} ${prefix}ERROR: ${message}\n`;
    
    // Write to console
    console.error(`${prefix}ERROR: ${message}`);
    
    // Write to file
    fs.appendFileSync(this.logFile, logMessage);
  }
}

export default Log;
