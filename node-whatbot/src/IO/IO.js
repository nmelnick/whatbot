/**
 * IO.js - Base class for IO modules
 * Matches Whatbot::IO from Perl version
 */

import Component from '../Component.js';
import Message from '../Message.js';

class IO extends Component {
  constructor({ my_config = {} } = {}) {
    super();
    this.myConfig = my_config;
    this._name = 'IO';
    this._me = null;
    this._controller = null;
  }

  get my_config() {
    return this.myConfig;
  }

  name(newName) {
    if (newName !== undefined) {
      this._name = newName;
    }
    return this._name;
  }

  me(newMe) {
    if (newMe !== undefined) {
      this._me = newMe;
    }
    return this._me;
  }

  get controller() {
    return this._controller;
  }

  set controller(ctrl) {
    this._controller = ctrl;
  }

  // To be implemented by subclasses
  async connect() {
    throw new Error('connect() must be implemented by subclass');
  }

  async disconnect() {
    throw new Error('disconnect() must be implemented by subclass');
  }

  async deliverMessage(message) {
    throw new Error('deliverMessage() must be implemented by subclass');
  }

  // Event methods
  async eventMessage(message) {
    if (!this.controller) {
      this.log().error('No controller set for IO');
      return;
    }

    const messages = await this.controller.handleMessage(message, this.me());
    
    for (const msg of messages) {
      await this.deliverMessage(msg);
    }
  }

  async eventUserEnter(channel, nick) {
    const target = `${this.name()}:${channel}`;
    const eventInfo = { nick };
    
    if (this.controller) {
      const messages = await this.controller.handleEvent(target, 'enter', eventInfo, this.me());
      for (const msg of messages) {
        await this.deliverMessage(msg);
      }
    }
  }

  async eventUserLeave(channel, nick, message = '') {
    const target = `${this.name()}:${channel}`;
    const eventInfo = { nick, message };
    
    if (this.controller) {
      const messages = await this.controller.handleEvent(target, 'leave', eventInfo, this.me());
      for (const msg of messages) {
        await this.deliverMessage(msg);
      }
    }
  }

  async eventUserChange(channel, oldNick, newNick) {
    const target = `${this.name()}:${channel}`;
    const eventInfo = { old_nick: oldNick, nick: newNick };
    
    if (this.controller) {
      const messages = await this.controller.handleEvent(target, 'user_change', eventInfo, this.me());
      for (const msg of messages) {
        await this.deliverMessage(msg);
      }
    }
  }

  async eventPing(source) {
    const target = `${this.name()}:${source}`;
    const eventInfo = { source };
    
    if (this.controller) {
      const messages = await this.controller.handleEvent(target, 'ping', eventInfo, this.me());
      for (const msg of messages) {
        await this.deliverMessage(msg);
      }
    }
  }

  async eventTopic(channel, topic, who) {
    const target = `${this.name()}:${channel}`;
    const eventInfo = { topic, nick: who };
    
    if (this.controller) {
      const messages = await this.controller.handleEvent(target, 'topic', eventInfo, this.me());
      for (const msg of messages) {
        await this.deliverMessage(msg);
      }
    }
  }

  getNewMessage({ from, to, content = '', text = '' }) {
    return new Message({
      from,
      to,
      content: content || text,
      me: this.me(),
      origin: `${this.name()}:${to}`
    });
  }

  async sendMessage(message) {
    return this.deliverMessage(message);
  }

  notify(context, message) {
    this.log().write(`[${this.name()}:${context}] ${message}`);
  }
}

export default IO;
