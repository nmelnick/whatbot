/**
 * Component.js - Base component for all whatbot modules
 * Matches Whatbot::Component from Perl version
 */

import State from './State.js';

class Component {
  constructor() {
    // Components get convenience accessors to state
  }

  state() {
    return State.instance();
  }

  parent() {
    return this.state().parent;
  }

  config() {
    return this.state().config;
  }

  ios() {
    return this.state().ios;
  }

  database() {
    return this.state().database;
  }

  log() {
    return this.state().log;
  }

  controller() {
    return this.state().controller;
  }

  models() {
    return this.state().models;
  }

  model(modelName) {
    const models = this.models();
    const key = modelName.toLowerCase();
    if (models[key]) {
      return models[key];
    }
    console.warn(`${this.constructor.name} tried to reference model "${modelName}" even though it does not exist.`);
    return null;
  }

  searchIos(ioSearch) {
    const ios = this.ios();
    for (const [name, io] of Object.entries(ios)) {
      if (name.includes(ioSearch)) {
        return io;
      }
    }
    return null;
  }

  sendMessage(ioPath, message) {
    const [ioSearch, target] = ioPath.split(':');
    let searchKey = ioSearch;
    let targetChannel = target;

    // Handle IRC shorthand: #channel instead of IRC:#channel
    if (!targetChannel && ioSearch.startsWith('#')) {
      targetChannel = ioSearch;
      searchKey = 'IRC';
    }

    const io = this.searchIos(searchKey);
    if (!io) {
      this.log().write(`IO could not be found for "${searchKey}".`);
      return;
    }

    message.from = io.me;
    if (targetChannel) {
      message.to = targetChannel;
    }
    return io.sendMessage(message);
  }

  tagUser(user) {
    user = user.replace(/[{}]/g, '');
    return `{!user=${user}}`;
  }
}

export default Component;
