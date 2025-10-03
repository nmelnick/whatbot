/**
 * Controller.js - Command processor and dispatcher
 * Matches Whatbot::Controller from Perl version
 */

import Component from './Component.js';
import Message from './Message.js';

class Controller extends Component {
  constructor({ skipExtensions = false, commands = [] } = {}) {
    super();
    this.command = {};
    this.commandName = {};
    this.commandShortName = {};
    this.skipExtensions = skipExtensions;
    this.commandsToLoad = commands;
    this.buildCommandMap();
  }

  buildCommandMap() {
    // Initialize empty priority buckets
    this.command = {
      primary: {},
      core: {},
      extension: {},
      last: {}
    };

    // Load provided commands
    for (const cmd of this.commandsToLoad) {
      this.loadCommand(cmd);
    }
    
    this.log().write('Controller initialized with command map.');
  }

  loadCommand(cmd) {
    const className = cmd.constructor.name;
    const priority = cmd.commandPriority.toLowerCase();
    
    // Skip extensions if requested
    if ((priority === 'extension' || priority === 'last') && this.skipExtensions) {
      return;
    }

    const runPaths = [];

    // Process patterns
    for (const pattern of cmd.patterns) {
      if (pattern.event) {
        this.addEvent(runPaths, pattern.event, pattern.method);
      } else if (pattern.pattern) {
        const obj = {
          function: pattern.method,
          match: pattern.pattern
        };
        
        if (pattern.stop) {
          obj.stop = true;
        }
        
        if (pattern.use_text) {
          obj.use_text = true;
        }
        
        if (pattern.filter) {
          obj.filter = pattern.filter;
        }
        
        runPaths.push(obj);
      }
    }

    // Add to command structure
    if (!this.command[priority]) {
      this.command[priority] = {};
    }
    
    this.command[priority][className] = runPaths;
    this.commandName[className] = cmd;
    this.commandShortName[cmd.name] = cmd;
    
    this.log().write(`-> ${className} loaded.`);
  }

  async handleMessage(message, me) {
    const messages = [];
    
    for (const priority of ['primary', 'core', 'extension', 'last']) {
      if (messages.length > 0 && priority === 'last') {
        break;
      }

      const commands = this.command[priority] || {};
      for (const [commandName, runPaths] of Object.entries(commands)) {
        const command = this.commandName[commandName];
        
        if (!command) continue;
        if (command.requireDirect && !message.is_direct) continue;

        for (const runPath of runPaths) {
          if (!runPath.match && !runPath.function) continue;
          if (runPath.event) continue; // Skip event handlers in message processing

          const listen = runPath.match || /.*/;
          const functionName = runPath.function;

          const contentMatch = runPath.use_text ? message.text : message.content;
          const matches = contentMatch.match(listen);
          
          if (matches) {
            let captures = matches.slice(1); // Remove full match, keep capture groups
            
            if (runPath.filter) {
              captures = captures.map(runPath.filter);
            }

            try {
              const result = await command[functionName](message, captures);
              this._parseResult(commandName, message, result, messages);
              
              if (runPath.stop) {
                break;
              }
            } catch (error) {
              messages.push(this._returnError(commandName, message, error));
            }
          }
        }
      }
    }

    return messages;
  }

  async handleEvent(target, event, eventInfo, me) {
    const [io, context] = target.split(':');
    const messages = [];

    for (const priority of ['primary', 'core', 'extension', 'last']) {
      if (messages.length > 0 && (priority === 'extension' || priority === 'last')) {
        break;
      }

      const commands = this.command[priority] || {};
      for (const [commandName, runPaths] of Object.entries(commands)) {
        const command = this.commandName[commandName];
        
        if (!command) continue;

        for (const runPath of runPaths) {
          if (!runPath.event || runPath.event !== event) continue;

          const functionName = runPath.function;
          const message = new Message({
            from: me,
            to: context,
            text: '',
            me: me
          });

          try {
            const result = await command[functionName](target, eventInfo);
            this._parseResult(commandName, message, result, messages);
            
            if (runPath.stop) {
              break;
            }
          } catch (error) {
            messages.push(this._returnError(commandName, message, error));
          }
        }
      }
    }

    return messages;
  }

  dumpCommandMap() {
    for (const priority of ['primary', 'core', 'extension']) {
      let commandCount = 0;
      this.log().write(`${priority.toUpperCase()}:`);

      const commands = this.command[priority] || {};
      for (const [commandName, runPaths] of Object.entries(commands)) {
        for (const runPath of runPaths) {
          if (runPath.match) {
            this.log().write(` /${runPath.match.source}/ => ${commandName}->${runPath.function}`);
          } else if (runPath.event) {
            this.log().write(` Event "${runPath.event}" => ${commandName}->${runPath.function}`);
          }
          commandCount++;
        }
      }

      if (commandCount === 0) {
        this.log().write(' none');
      }
    }
  }

  _returnError(commandName, message, error) {
    this.log().error(`Failure in ${commandName}: ${error.message}`);
    this.log().error(error.stack);
    return message.reply({
      text: `${commandName} completely failed at that last remark.`
    });
  }

  _parseResult(commandName, message, result, messages) {
    if (result === undefined || result === null) {
      return;
    }

    if (result === 'last_run') {
      return;
    }

    this.log().write(`%%% Message handled by ${commandName}`);

    const results = Array.isArray(result) ? result : [result];

    for (const resultSingle of results) {
      let outMessage;
      
      if (resultSingle instanceof Message) {
        outMessage = resultSingle;
      } else {
        outMessage = message.reply({ text: resultSingle });
      }
      
      messages.push(outMessage);
    }
  }

  addRunPath(runPaths, match, functionName) {
    const obj = {
      function: functionName
    };

    // Handle {!user} pattern
    if (match.includes('{!user}')) {
      match = match.replace(/\{!user\}/g, '({!user=[\\w_]+?}|[\\w_]+)');
      obj.use_text = true;
      obj.filter = (str) => str.replace(/\{!user=([\w_]+?)\}/g, '$1');
    }

    obj.match = new RegExp(match, 'i');
    runPaths.push(obj);
  }

  addEvent(runPaths, event, functionName) {
    runPaths.push({
      event: event,
      function: functionName
    });
  }
}

export default Controller;
