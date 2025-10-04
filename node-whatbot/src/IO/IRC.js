import IO from './IO.js';

class IRC extends IO {
  constructor(config) {
    super(config);
    this.handle = null;
    this.forceDisconnect = false;
    this.channels = [];
    this.channelsHash = {};
    
    const name = 'IRC_' + this.myConfig.host.replace(/ /g, '_');
    this._name = name;
    this.setMe(this.myConfig.nick);
    
    this._buildChannels();
  }

  _buildChannels() {
    let channels = this.myConfig.channel;
    if (!Array.isArray(channels)) {
      channels = [channels];
    }
    this.channels = channels;
  }

  async connect() {
    const config = this.myConfig;
    
    this.log.write(`Connecting to ${config.host}:${config.port}.`);

    try {
      const { default: IrcFramework } = await import('irc-framework');
      
      this.handle = new IrcFramework.Client();
      this.handle.connect({
        host: config.host,
        port: config.port || 6667,
        nick: config.nick,
        username: config.username || config.nick,
        gecos: config.realname || config.nick,
        tls: config.ssl || false,
        password: config.hostpassword,
        encoding: 'utf-8'
      });
      
      this.forceDisconnect = false;
    } catch (err) {
      this.log.error('IRC module not available. Install with: npm install irc-framework');
      throw new Error('IRC module not available');
    }

    this.handle.on('registered', () => this._onConnect());
    this.handle.on('message', (from, to, text) => this._onMessage(from, to, text));
    this.handle.on('join', (channel, nick) => this._onJoin(channel, nick));
    this.handle.on('part', (channel, nick, reason) => this._onPart(channel, nick, reason));
    this.handle.on('nick', (oldNick, newNick, channels) => this._onNick(oldNick, newNick, channels));
    this.handle.on('topic', (channel, topic, nick) => this._onTopic(channel, topic, nick));
    this.handle.on('error', (message) => this._onError(message));
    this.handle.on('close', () => this._onDisconnect());
    this.handle.on('ping', (server) => this._onPing(server));
    this.handle.on('ctcp-privmsg', (from, to, text, type) => this._onCTCP(from, to, text, type));
  }

  async disconnect() {
    this.forceDisconnect = true;
    if (this.handle) {
      const quitMessage = this.myConfig.quitmessage || 'Goodbye';
      this.handle.disconnect(quitMessage);
    }
  }

  deliverMessage(message) {
    const charactersPerLine = 502 - message.to.length - 10;
    const lines = [];
    const messageWords = message.content.split(/\s+/);

    let line = '';
    for (const word of messageWords) {
      if (word.length > charactersPerLine) {
        let msg = message.content;
        line = '';
        lines.length = 0;
        while (msg.length > 0) {
          lines.push(msg.substring(0, charactersPerLine));
          msg = msg.substring(charactersPerLine);
        }
        break;
      } else {
        if (line.length + word.length + 1 > charactersPerLine) {
          lines.push(line);
          line = '';
        }
        if (line) line += ' ';
        line += word;
      }
    }
    if (line) lines.push(line);

    if (message.content.match(/^\/me (.*)/)) {
      const action = message.content.replace(/^\/me /, '');
      this.handle.action(message.to, action);
      this.eventAction(this.me, message.from, message.content);
    } else {
      for (const outLine of lines) {
        this._privmsg(message.to, outLine);
        message.content = outLine;
        this.eventMessage(message);
        const delay = Math.floor(Math.random() * 2000);
        setTimeout(() => {}, delay);
      }
    }
  }

  _privmsg(to, message) {
    if (this.handle) {
      this.handle.say(to, message);
    }
  }

  _onConnect() {
    this.setMe(this.handle.nick);

    for (const channel of this.channels) {
      const name = typeof channel === 'string' ? channel : channel.name;
      const password = typeof channel === 'object' ? channel.channelpassword : undefined;
      
      this.handle.join(name, password);
      this.channelsHash[name] = channel;
      this.notify(name, 'Joined.');

      if (typeof channel === 'object' && channel.joinmessage) {
        this._privmsg(name, channel.joinmessage);
      }
    }
  }

  _onDisconnect() {
    if (!this.forceDisconnect) {
      this.handle = null;
      this.notify('X', 'Disconnected, attempting to reconnect...');
      setTimeout(() => {
        this.connect();
      }, 3000);
    }
  }

  _onJoin(channel, nick) {
    if (nick === this.me) return;
    this.eventUserEnter(channel, nick);
  }

  _onPart(channel, nick, reason) {
    if (nick === this.me) return;
    this.eventUserLeave(channel, nick, reason);
  }

  _onMessage(from, to, text) {
    const message = this.getNewMessage({
      from: from,
      to: to === this.me ? from : to,
      content: text
    });
    this.eventMessage(message);
  }

  _onPing(server) {
    this.notify('*', `*** PING from ${server}`);
    this.eventPing(server);
  }

  _onTopic(channel, topic, who) {
    if (!channel.startsWith('#')) return;
    this.notify(channel, `*** The topic is '${topic}'.`);
    this.eventTopic(channel, topic, who);
  }

  _onNick(oldNick, newNick, channels) {
    if (oldNick === this.me || newNick === this.me) return;
    for (const channel of channels) {
      this.eventUserChange(channel, oldNick, newNick);
    }
  }

  _onCTCP(from, to, text, type) {
    if (type === 'ACTION') {
      this.eventAction(to, from, text);
    }
  }

  _onError(message) {
    this.log.error(`IRC error: ${JSON.stringify(message)}`);
  }
}

export default IRC;
