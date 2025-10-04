/**
 * Config.js - Configuration file loader
 * Matches Whatbot::Config from Perl version
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

class Config {
  constructor(configPath) {
    this.configFile = configPath || this.findConfigFile();
    if (!this.configFile) {
      throw new Error('Configuration file not found.');
    }
    
    this.configHash = this.loadConfig();
  }

  findConfigFile() {
    const basedir = path.resolve(__dirname, '../..');
    const searchPaths = [
      path.join(process.env.HOME || '', '.whatbot/whatbot.conf'),
      '/usr/local/etc/whatbot/whatbot.conf',
      '/usr/local/etc/whatbot.conf',
      '/etc/whatbot/whatbot.conf',
      '/etc/whatbot.conf',
      path.join(basedir, 'conf/whatbot.conf'),
      path.join(__dirname, '../config/whatbot.conf'),
    ];

    for (const configPath of searchPaths) {
      if (fs.existsSync(configPath)) {
        return configPath;
      }
    }

    return null;
  }

  loadConfig() {
    const data = fs.readFileSync(this.configFile, 'utf8');
    const config = JSON.parse(data);
    
    // Add Timer IO (auto-loaded like Perl version)
    if (!config.io) {
      config.io = [];
    }
    
    return config;
  }

  get io() {
    return this.configHash.io || [];
  }

  get database() {
    return this.configHash.database || {};
  }

  get commands() {
    return this.configHash.commands || {};
  }

  get logDirectory() {
    return this.configHash.log?.directory || '/tmp/whatbot';
  }

  get config_hash() {
    return this.configHash;
  }
}

export default Config;
