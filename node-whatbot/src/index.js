#!/usr/bin/env node

/**
 * index.js - Main entry point for node-whatbot
 * Matches Whatbot.pm from Perl version
 */

import Config from './Config.js';
import Log from './Log.js';
import State from './State.js';
import Controller from './Controller.js';
import Console from './IO/Console.js';
import Discord from './IO/Discord.js';
import IRC from './IO/IRC.js';
import Slack from './IO/Slack.js';
import Timer from './IO/Timer.js';
import Web from './IO/Web.js';
import LogIO from './IO/Log.js';
import LogInfobot from './IO/Log/Infobot.js';
import SQLite from './Database/SQLite.js';
import PostgreSQL from './Database/PostgreSQL.js';
import MySQL from './Database/MySQL.js';
import Karma from './Database/Table/Karma.js';
import Factoid from './Database/Table/Factoid.js';
import UserAlias from './Database/Table/UserAlias.js';
import Seen from './Database/Table/Seen.js';
import Quote from './Database/Table/Quote.js';
import Soup from './Database/Table/Soup.js';
import URL from './Database/Table/URL.js';
import Bother from './Database/Table/Bother.js';
import PasteTable from './Database/Table/Paste.js';

const VERSION = '0.2.0';

class Whatbot {
  constructor() {
    this.version = VERSION;
    this.skipExtensions = false;
    this.initialConfig = null;
  }

  async config(configPath) {
    try {
      this.initialConfig = new Config(configPath);
    } catch (error) {
      this.reportError(`Configuration error: ${error.message}`);
    }
  }

  async run(overrideIo) {
    if (!this.initialConfig || !this.initialConfig.config_hash) {
      this.reportError('Invalid configuration');
    }

    // Override IO if specified
    if (overrideIo) {
      this.initialConfig.configHash.io = [overrideIo];
    }

    // Start Logger
    const log = new Log({
      log_directory: this.initialConfig.logDirectory
    });

    if (!log || !log.log_directory) {
      this.reportError('Invalid configuration: Missing or unavailable log directory');
    }

    // Build state
    State.initialize({
      parent: this,
      config: this.initialConfig,
      log: log
    });

    // Initialize database
    await this._initializeDatabase();

    // Initialize IO modules
    const ios = await this._initializeIo();

    // Load commands
    const commands = await this._loadCommands();

    // Create Controller
    const controller = new Controller({
      skipExtensions: this.skipExtensions,
      commands: commands
    });
    State.instance().controller = controller;
    controller.dumpCommandMap();

    // Connect to IO
    for (const ioObject of ios) {
      log.write(`Sending connect to ${ioObject.constructor.name}`);
      ioObject.controller = controller;
      await ioObject.connect();
    }

    // Log successful initialization
    log.write('whatbot initialized successfully.');

    // Handle shutdown
    process.on('SIGINT', () => {
      this.stop(ios, log);
    });

    process.on('SIGTERM', () => {
      this.stop(ios, log);
    });
  }

  async _initializeDatabase() {
    const state = State.instance();
    const dbConfig = this.initialConfig.database;

    if (!dbConfig || !dbConfig.handler) {
      this.reportError('Invalid database configuration');
    }

    // Start database handler
    let database;
    if (dbConfig.handler === 'SQLite') {
      database = new SQLite();
    } else if (dbConfig.handler === 'PostgreSQL') {
      database = new PostgreSQL();
    } else if (dbConfig.handler === 'MySQL') {
      database = new MySQL();
    } else {
      this.reportError(`Unsupported database handler: ${dbConfig.handler}`);
    }

    await database.connect();
    if (!database.handle) {
      this.reportError('Database connection failed');
    }

    state.database = database;

    // Initialize table models
    const models = {};
    
    try {
      models.karma = new Karma({ handle: database.handle });
      state.log.write('-> Karma model loaded.');
    } catch (error) {
      state.log.error('Error loading Karma model: ' + error.message);
    }

    try {
      models.factoid = new Factoid({ handle: database.handle });
      state.log.write('-> Factoid model loaded.');
    } catch (error) {
      state.log.error('Error loading Factoid model: ' + error.message);
    }

    try {
      models.useralias = new UserAlias({ handle: database.handle });
      state.log.write('-> UserAlias model loaded.');
    } catch (error) {
      state.log.error('Error loading UserAlias model: ' + error.message);
    }

    try {
      models.seen = new Seen({ handle: database.handle });
      state.log.write('-> Seen model loaded.');
    } catch (error) {
      state.log.error('Error loading Seen model: ' + error.message);
    }

    try {
      models.quote = new Quote({ handle: database.handle });
      state.log.write('-> Quote model loaded.');
    } catch (error) {
      state.log.error('Error loading Quote model: ' + error.message);
    }

    try {
      models.soup = new Soup({ handle: database.handle });
      await models.soup.init();
      state.log.write('-> Soup model loaded.');
    } catch (error) {
      state.log.error('Error loading Soup model: ' + error.message);
    }

    try {
      models.url = new URL({ handle: database.handle });
      await models.url.init();
      state.log.write('-> URL model loaded.');
    } catch (error) {
      state.log.error('Error loading URL model: ' + error.message);
    }

    try {
      models.bother = new Bother({ handle: database.handle });
      state.log.write('-> Bother model loaded.');
    } catch (error) {
      state.log.error('Error loading Bother model: ' + error.message);
    }

    try {
      models.paste = new PasteTable({ handle: database.handle });
      state.log.write('-> Paste model loaded.');
    } catch (error) {
      state.log.error('Error loading Paste model: ' + error.message);
    }

    state.models = models;
  }

  async _loadCommands() {
    const commands = [];
    
    try {
      // Primary commands
      const { default: HelpCommand } = await import('./Command/Help.js');
      commands.push(new HelpCommand({ name: 'help' }));
      
      const { default: AdminCommand } = await import('./Command/Admin.js');
      commands.push(new AdminCommand({ name: 'admin' }));
      
      const { default: AwarenessCommand } = await import('./Command/Awareness.js');
      commands.push(new AwarenessCommand({ name: 'awareness' }));
      
      // Core commands
      const { default: KarmaCommand } = await import('./Command/Karma.js');
      commands.push(new KarmaCommand({ name: 'karma' }));
      
      const { default: FactoidCommand } = await import('./Command/Factoid.js');
      commands.push(new FactoidCommand({ name: 'factoid' }));
      
      const { default: DashboardCommand } = await import('./Command/Dashboard.js');
      commands.push(new DashboardCommand({ name: 'dashboard' }));
      
      const { default: SeenCommand } = await import('./Command/Seen.js');
      commands.push(new SeenCommand({ name: 'seen' }));
      
      // Extension commands
      const { default: QuoteCommand } = await import('./Command/Quote.js');
      commands.push(new QuoteCommand({ name: 'quote' }));
      
      const { default: TellCommand } = await import('./Command/Tell.js');
      commands.push(new TellCommand({ name: 'tell' }));
      
      const { default: URLCommand } = await import('./Command/URL.js');
      commands.push(new URLCommand({ name: 'url' }));
      
      const { default: DefineCommand } = await import('./Command/Define.js');
      commands.push(new DefineCommand({ name: 'define' }));
      
      const { default: MathCommand } = await import('./Command/Math.js');
      commands.push(new MathCommand({ name: 'math' }));
      
      const { default: ConvertCommand } = await import('./Command/Convert.js');
      commands.push(new ConvertCommand({ name: 'convert' }));
      
      const { default: KarmaHistoryCommand } = await import('./Command/KarmaHistory.js');
      commands.push(new KarmaHistoryCommand({ name: 'karmahistory' }));
      
      const { default: BotherCommand } = await import('./Command/Bother.js');
      commands.push(new BotherCommand({ name: 'bother' }));
      
      const { default: AtCommand } = await import('./Command/At.js');
      commands.push(new AtCommand({ name: 'at' }));
      
      const { default: PasteCommand } = await import('./Command/Paste.js');
      commands.push(new PasteCommand({ name: 'paste' }));
      
      const { default: CalendarCommand } = await import('./Command/Calendar.js');
      commands.push(new CalendarCommand({ name: 'calendar' }));
      
      const { default: APICommand } = await import('./Command/API.js');
      commands.push(new APICommand({ name: 'api' }));
      
      const { default: WeatherCommand } = await import('./Command/Weather.js');
      const weatherConfig = this.initialConfig.configHash.command?.weather || {};
      commands.push(new WeatherCommand({ name: 'weather', my_config: weatherConfig }));
      
      const { default: TriggerCommand } = await import('./Command/Trigger.js');
      commands.push(new TriggerCommand({ name: 'trigger' }));
      
      const { default: NslookupCommand } = await import('./Command/Nslookup.js');
      commands.push(new NslookupCommand({ name: 'nslookup' }));
      
      const { default: ExcuseCommand } = await import('./Command/Excuse.js');
      commands.push(new ExcuseCommand({ name: 'excuse' }));
      
      const { default: InsultCommand } = await import('./Command/Insult.js');
      commands.push(new InsultCommand({ name: 'insult' }));
      
      const { default: NickometerCommand } = await import('./Command/Nickometer.js');
      commands.push(new NickometerCommand({ name: 'nickometer' }));
      
      const { default: PingCommand } = await import('./Command/Ping.js');
      commands.push(new PingCommand({ name: 'ping' }));
      
      // Last priority
      const { default: FactoidListenerCommand } = await import('./Command/FactoidListener.js');
      commands.push(new FactoidListenerCommand({ name: 'factoidlistener' }));
      
      const { default: AnnoyingCommand } = await import('./Command/Annoying.js');
      commands.push(new AnnoyingCommand({ name: 'annoying' }));
      
      const { default: BlackjackCommand } = await import('./Command/Blackjack.js');
      commands.push(new BlackjackCommand({ name: 'blackjack' }));
    } catch (error) {
      console.error('Error loading commands:', error);
      throw error;
    }

    return commands;
  }

  async _initializeIo() {
    const ioModules = [];
    const iosHash = {};
    const state = State.instance();

    for (const ioConfig of this.initialConfig.io) {
      if (!ioConfig.interface) {
        state.log.error('No interface designated for one or more IO modules');
        continue;
      }

      let ioObject;
      try {
        switch (ioConfig.interface) {
          case 'Console':
            ioObject = new Console({ my_config: ioConfig });
            break;
          case 'Discord':
            ioObject = new Discord({ my_config: ioConfig });
            break;
          case 'IRC':
            ioObject = new IRC({ my_config: ioConfig });
            break;
          case 'Slack':
            ioObject = new Slack({ my_config: ioConfig });
            break;
          case 'Timer':
            ioObject = new Timer({ my_config: ioConfig });
            break;
          case 'Web':
            ioObject = new Web({ my_config: ioConfig });
            break;
          case 'Jabber':
            try {
              const { default: Jabber } = await import('./IO/Jabber.js');
              ioObject = new Jabber({ my_config: ioConfig });
            } catch (err) {
              throw new Error(`Jabber requires '@xmpp/client' package: npm install @xmpp/client`);
            }
            break;
          case 'Log':
            ioObject = new LogIO({ my_config: ioConfig });
            break;
          case 'Log::Infobot':
            ioObject = new LogInfobot({ my_config: ioConfig });
            break;
          default:
            throw new Error(`Unknown IO interface: ${ioConfig.interface}`);
        }

        iosHash[ioObject.name()] = ioObject;
        ioModules.push(ioObject);
      } catch (error) {
        this.reportError(`Error loading ${ioConfig.interface}: ${error.message}`);
      }
    }

    state.ios = iosHash;
    return ioModules;
  }

  async stop(ios, log) {
    log.write('Received interrupt.');
    log.write('whatbot exiting.');
    
    for (const ioObject of ios) {
      log.write(`Sending disconnect to ${ioObject.constructor.name}`);
      await ioObject.disconnect();
    }
    
    process.exit(0);
  }

  reportError(errorMessage) {
    if (State.instance() && State.instance().log) {
      State.instance().log.error(errorMessage);
    }
    console.error('ERROR:', errorMessage);
    process.exit(1);
  }
}

// Main execution
async function main() {
  const bot = new Whatbot();
  
  // Parse command line arguments
  const args = process.argv.slice(2);
  let configPath = null;
  
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '-c' && args[i + 1]) {
      configPath = args[i + 1];
      break;
    }
  }

  await bot.config(configPath);
  await bot.run();
}

// Run if this is the main module
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
  });
}

export default Whatbot;
