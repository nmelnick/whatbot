/**
 * Command.js - Base class for whatbot commands
 * Matches Whatbot::Command from Perl version
 */

import Component from '../Component.js';

class Command extends Component {
  constructor({ name = '', my_config = {} } = {}) {
    super();
    this.name = name;
    this.commandPriority = 'Extension';
    this.requireDirect = false;
    this.myConfig = my_config;
    this.patterns = [];
    this.register();
  }

  get my_config() {
    return this.myConfig;
  }

  // Override this in subclasses
  register() {
    // Set command priority and patterns here
  }

  help() {
    return 'Help is not available for this module.';
  }

  // Helper methods for pattern registration
  command(methodName) {
    const pattern = `^${this.name} +${methodName} *([^\\b]+)*`;
    this.patterns.push({
      type: 'Command',
      pattern: new RegExp(pattern, 'i'),
      method: methodName
    });
  }

  commandRegEx(regex, methodName) {
    const pattern = `^${this.name} +${regex}`;
    this.patterns.push({
      type: 'CommandRegEx',
      pattern: new RegExp(pattern, 'i'),
      method: methodName
    });
  }

  globalRegEx(regex, methodName) {
    this.patterns.push({
      type: 'GlobalRegEx',
      pattern: new RegExp(regex, 'i'),
      method: methodName
    });
  }

  monitor(methodName) {
    this.patterns.push({
      type: 'Monitor',
      pattern: /.*/,
      method: methodName
    });
  }

  event(eventName, methodName) {
    this.patterns.push({
      type: 'Event',
      event: eventName,
      method: methodName
    });
  }

  stopAfter(methodName) {
    // Find the pattern for this method and mark it
    for (const pattern of this.patterns) {
      if (pattern.method === methodName) {
        pattern.stop = true;
      }
    }
  }
}

export default Command;
