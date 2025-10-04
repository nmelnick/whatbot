/**
 * Discord.js - Discord IO for whatbot
 * Matches Whatbot::IO::Discord from Perl version
 */

import { Client, GatewayIntentBits } from "discord.js";
import IO from "./IO.js";

class Discord extends IO {
  constructor(config) {
    super(config);

    if (!this.my_config.token) {
      throw new Error("IO->Discord is missing an access token");
    }

    this.token = this.my_config.token;
    this.name(`Discord_${this.token.substring(0, 8)}`);
    this.client = null;
    this.channels = {}; // id -> name mapping
    this.users = {}; // id -> username mapping
  }

  async connect() {
    this.log().write("Connecting to Discord...");

    this.client = new Client({
      intents: [
        GatewayIntentBits.Guilds,
        GatewayIntentBits.GuildMessages,
        GatewayIntentBits.MessageContent,
        GatewayIntentBits.GuildMembers,
      ],
    });

    this.client.on("clientReady", () => {
      this._onReady();
    });

    this.client.on("messageCreate", (message) => {
      this._onMessage(message);
    });

    this.client.on("disconnect", () => {
      this._onDisconnect();
    });

    await this.client.login(this.token);
  }

  async disconnect() {
    if (this.client) {
      await this.client.destroy();
    }
  }

  async deliverMessage(message) {
    // Find channel by name
    let channelId = null;
    for (const [id, name] of Object.entries(this.channels)) {
      if (name === message.to) {
        channelId = id;
        break;
      }
    }

    if (!channelId) {
      this.log().write(`Could not find target channel for: ${message.to}`);
      return;
    }

    const channel = await this.client.channels.fetch(channelId);
    if (channel && channel.isTextBased()) {
      // Convert {!user=name} tags to Discord mentions
      let content = message.content;
      content = content.replace(/\{!user=(\w+)\}/g, (match, username) => {
        return this.formatUser(username);
      });

      await channel.send(content);
    }
  }

  formatUser(user) {
    // Strip leading @
    user = user.replace(/^@/, "");

    // Find user ID by name
    for (const [id, username] of Object.entries(this.users)) {
      if (username === user) {
        return `<@${id}>`;
      }
    }

    return user;
  }

  async startTyping(channelName) {
    let channelId = null;
    for (const [id, name] of Object.entries(this.channels)) {
      if (name === channelName) {
        channelId = id;
        break;
      }
    }

    if (channelId) {
      const channel = await this.client.channels.fetch(channelId);
      if (channel && channel.isTextBased()) {
        await channel.sendTyping();
      }
    }
  }

  _onReady() {
    this.log().write("Connected to Discord.");
    this.me(this.client.user.username);
    this.log().write(`Using 'me' value of ${this.me()}`);

    // Cache channels
    this.client.channels.cache.forEach((channel) => {
      if (channel.isTextBased()) {
        this.channels[channel.id] = channel.name;
      }
    });

    // Cache users
    this.client.guilds.cache.forEach((guild) => {
      guild.members.cache.forEach((member) => {
        this.users[member.id] = member.user.username;
      });
    });
  }

  _onDisconnect() {
    this.log().write("Discord received disconnect.");
  }

  async _onMessage(discordMessage) {
    // Ignore bot's own messages
    if (discordMessage.author.id === this.client.user.id) {
      return;
    }

    let text = discordMessage.content;

    // Strip link formatting <http://...> -> http://...
    text = text.replace(/<(https?:\/\/.*?)>/g, "$1");

    // Convert Discord mentions to {!user=name} tags
    text = text.replace(/<@!?(\d+)>/g, (match, userId) => {
      return this._getUser(userId);
    });

    const message = this.getNewMessage({
      from:
        discordMessage.member?.displayName || discordMessage.author.username,
      to: discordMessage.channel.name,
      content: text,
    });

    await this.eventMessage(message);
  }

  _getUser(userId) {
    if (!userId) return "";
    const username = this.users[userId] || userId;
    return this.tagUser(username);
  }
}

export default Discord;
