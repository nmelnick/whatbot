import IO from './IO.js';

class Slack extends IO {
  constructor(config) {
    super(config);
    
    if (!this.myConfig.token) {
      throw new Error('IO->Slack is missing an access token');
    }
    
    this.token = this.myConfig.token;
    this.handle = null;
    this.webClient = null;
    this.forceDisconnect = false;
    this.users = {};
    this.channels = {};
    
    this._name = 'Slack_' + this.token;
  }

  async connect() {
    try {
      const { WebClient, RTMClient } = await import('@slack/web-api');
      
      this.handle = new RTMClient(this.token);
      this.webClient = new WebClient(this.token);
      
      this._registerCallbacks();
      
      setTimeout(async () => {
        this.log.write('Connecting to Slack.');
        await this.handle.start();
      }, 4000);
    } catch (err) {
      this.log.error('Slack module not available. Install with: npm install @slack/web-api');
      throw new Error('Slack module not available');
    }
  }

  async disconnect() {
    this.forceDisconnect = true;
    if (this.handle) {
      await this.handle.disconnect();
    }
  }

  deliverMessage(message) {
    let to = null;
    
    for (const [channelId, channelName] of Object.entries(this.channels)) {
      if (channelName === message.to) {
        to = channelId;
        break;
      }
    }
    
    if (!to) {
      this.log.write('Could not find target channel for: ' + message.to);
      return;
    }
    
    this.handle.sendMessage(message.content, to)
      .then(() => {
        this.eventMessage(message);
      })
      .catch(err => {
        this.log.error('Failed to send Slack message: ' + err.message);
      });
  }

  formatUser(user) {
    user = user.replace(/^@/, '');
    
    for (const [id, name] of Object.entries(this.users)) {
      if (name === user) {
        return `<@${id}|${name}>`;
      }
    }
    
    return user;
  }

  _registerCallbacks() {
    this.handle.on('authenticated', async (event) => {
      await this._onHello(event);
    });
    
    this.handle.on('message', (event) => {
      this._onMessage(event);
    });
    
    this.handle.on('disconnected', () => {
      this._onFinish();
    });
    
    this.handle.on('channel_created', (event) => {
      this._onChannelCreated(event);
    });
    
    this.handle.on('channel_joined', (event) => {
      this._onChannelJoined(event);
    });
    
    this.handle.on('member_joined_channel', (event) => {
      this._onChannelJoin(event);
    });
    
    this.handle.on('user_change', (event) => {
      this._onUserChange(event);
    });
  }

  async _onHello(event) {
    this.log.write('Connected to Slack.');
    
    setTimeout(async () => {
      try {
        const usersList = await this.webClient.users.list();
        for (const user of usersList.members) {
          this.users[user.id] = user.name;
        }
        
        const channelsList = await this.webClient.conversations.list({
          types: 'public_channel,private_channel'
        });
        for (const channel of channelsList.channels) {
          this.channels[channel.id] = channel.name;
        }
        
        this.setMe(event.self.name || 'whatbot');
        
        this.log.write('Slack initialized.');
      } catch (err) {
        this.log.error('Failed to fetch Slack metadata: ' + err.message);
      }
    }, 5000);
  }

  _onMessage(event) {
    if (event.hidden || event.thread_ts || Object.keys(this.users).length === 0) {
      return;
    }
    
    const message = this._slackMessageToMessage(event);
    if (message) {
      this.eventMessage(message);
    }
  }

  _onChannelJoined(event) {
    if (event.channel && event.channel.name) {
      this.log.write('** Joined ' + event.channel.name);
    }
  }

  _onChannelJoin(event) {
    // User joined channel event
  }

  _onFinish() {
    this.log.write('Disconnected from Slack.');
    this.forceDisconnect = false;
    
    this.users = {};
    this.channels = {};
    
    if (!this.forceDisconnect) {
      setTimeout(() => {
        this.connect();
      }, 3000);
    }
  }

  _onChannelCreated(event) {
    if (event.channel) {
      this.channels[event.channel.id] = event.channel.name;
      this.log.write('New channel: ' + event.channel.name);
    }
  }

  _onUserChange(event) {
    if (event.user) {
      this.users[event.user.id] = event.user.name;
      this.log.write('New/changed user: ' + event.user.name);
    }
  }

  _slackMessageToMessage(slackMessage) {
    if (!slackMessage.text || !slackMessage.user || !slackMessage.channel) {
      return null;
    }
    
    let text = slackMessage.text;
    
    text = text.replace(/<(http.*?)>/g, '$1');
    text = text.replace(/<@\w+?\|(\w+)>/g, (match, name) => this._getUser(name));
    text = text.replace(/<@(\w+?)>/g, (match, id) => this._getUser(id));
    
    text = this._stripHtml(text);
    
    return this.getNewMessage({
      from: this.users[slackMessage.user] || slackMessage.user,
      to: this.channels[slackMessage.channel] || slackMessage.channel,
      content: text
    });
  }

  _getUser(id) {
    return this.tagUser(this.users[id] || id);
  }

  _stripHtml(html) {
    return html
      .replace(/<script[^>]*>.*?<\/script>/gis, '')
      .replace(/<style[^>]*>.*?<\/style>/gis, '')
      .replace(/<[^>]+>/g, '')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'")
      .trim();
  }
}

export default Slack;
