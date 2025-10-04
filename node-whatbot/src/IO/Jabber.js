import IO from './IO.js';
import { client as XMPPClient, xml } from '@xmpp/client';

class Jabber extends IO {
  constructor(config) {
    super(config);
    
    const jabberId = this.myConfig.jabber_id;
    const host = this.myConfig.host;
    
    if (!jabberId || !this.myConfig.password || !host) {
      throw new Error('Jabber component requires "jabber_id", "password", and "host"');
    }
    
    const name = 'Jabber_' + host.replace(/[\s\.]/g, '_');
    this.name = name;
    this.me = jabberId;
    
    this.handle = null;
    this.forceDisconnect = false;
    this.rooms = new Map();
    
    let channels = this.myConfig.channel;
    if (!Array.isArray(channels)) {
      channels = [channels];
    }
    this.channels = channels;
  }

  async connect() {
    const config = this.myConfig;
    const port = config.port || 5222;
    const service = `xmpp://${config.host}:${port}`;
    
    this.handle = XMPPClient({
      service,
      domain: config.host,
      username: config.jabber_id.split('@')[0],
      password: config.password,
      resource: 'bot'
    });

    this.log.write(`Connecting to ${config.host}:${port}.`);

    this.handle.on('error', (err) => {
      console.error('XMPP Error:', err);
    });

    this.handle.on('offline', () => {
      if (!this.forceDisconnect) {
        this.notify('X', 'Disconnected, attempting to reconnect...');
        setTimeout(() => {
          this.handle.start().catch(console.error);
        }, 3000);
      }
    });

    this.handle.on('online', async (address) => {
      const presenceStatus = config.presence_status || '';
      const presencePriority = config.presence_priority || 0;
      
      await this.handle.send(xml('presence', {}, 
        xml('status', {}, presenceStatus),
        xml('priority', {}, presencePriority.toString())
      ));

      const conferenceServer = config.conference_server;
      if (conferenceServer && this.channels) {
        for (const room of this.channels) {
          const roomJid = `${room}@${conferenceServer}`;
          this.log.write(`Joining ${roomJid}`);
          
          const nick = config.nick || address.local;
          this.rooms.set(roomJid, { nick });
          
          await this.handle.send(xml('presence', { to: `${roomJid}/${nick}` },
            xml('x', { xmlns: 'http://jabber.org/protocol/muc' },
              xml('history', { maxchars: '0' })
            )
          ));
        }
      }
    });

    this.handle.on('stanza', async (stanza) => {
      if (stanza.is('message')) {
        await this._handleMessage(stanza);
      } else if (stanza.is('presence')) {
        await this._handlePresence(stanza);
      }
    });

    await this.handle.start();
  }

  async disconnect() {
    this.forceDisconnect = true;
    const quitMessage = this.myConfig.quitmessage || 'Disconnecting';
    await this.handle.send(xml('presence', { type: 'unavailable' },
      xml('status', {}, quitMessage)
    ));
    await this.handle.stop();
  }

  async deliverMessage(message) {
    message.from = message.from || this.myConfig.jabber_id;
    
    const room = this.rooms.get(message.to);
    if (room) {
      await this.handle.send(
        xml('message', { to: message.to, type: 'groupchat' },
          xml('body', {}, message.content)
        )
      );
    } else {
      await this.handle.send(
        xml('message', { to: message.to, type: 'chat' },
          xml('body', {}, message.content)
        )
      );
    }
    
    this.eventMessage(message);
  }

  async _handleMessage(stanza) {
    const from = stanza.attrs.from;
    const to = stanza.attrs.to;
    const type = stanza.attrs.type;
    const bodyEl = stanza.getChild('body');
    
    if (!bodyEl) return;
    
    const body = bodyEl.text();
    if (!body) return;

    if (type === 'groupchat') {
      const [roomJid, nick] = from.split('/');
      const room = this.rooms.get(roomJid);
      
      if (!nick) return;
      if (nick === room?.nick) return;
      
      this.eventMessage(
        this.getNewMessage({
          replyTo: roomJid,
          from: nick,
          to: roomJid,
          content: body,
          me: room?.nick
        })
      );
    } else {
      const fromJid = from.split('/')[0];
      this.eventMessage(
        this.getNewMessage({
          replyTo: from,
          from: fromJid,
          to: to,
          content: body,
          me: to
        })
      );
    }
  }

  async _handlePresence(stanza) {
    const from = stanza.attrs.from;
    const type = stanza.attrs.type;
    const [roomJid, nick] = from.split('/');
    
    if (!nick) return;
    
    const room = this.rooms.get(roomJid);
    if (!room) return;
    
    if (nick === room.nick) return;
    
    if (type === 'unavailable') {
      this.eventUserLeave(roomJid, nick);
    } else if (!type) {
      this.eventUserEnter(roomJid, nick);
    }
  }
}

export default Jabber;
