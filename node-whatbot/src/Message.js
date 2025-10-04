/**
 * Message.js - Wrapper class for whatbot message passing
 * Matches Whatbot::Message from Perl version
 */

import Component from './Component.js';

class Message extends Component {
  constructor({ from, to, content = '', text = '', timestamp = null, is_direct = 0, me = null, origin = null, invisible = false, reply_to = null }) {
    super();
    
    if (!from || !to) {
      throw new Error('Message requires "from" and "to" fields');
    }

    this.from = from;
    this.to = to;
    this.reply_to = reply_to || null;
    this._content = '';
    this._text = '';
    this.timestamp = timestamp || Math.floor(Date.now() / 1000);
    this.is_direct = is_direct ? 1 : 0;
    this.me = me;
    this.origin = origin;
    this.invisible = invisible;

    // Set content or text (will trigger processing)
    if (text) {
      this.text = text;
    } else if (content) {
      this.content = content;
    }

    // Check if message is directed at bot
    this._checkDirect();
  }

  get content() {
    return this._content;
  }

  set content(value) {
    value = value.trim();
    this._content = value;
    this._text = value;
  }

  get text() {
    return this._text;
  }

  set text(value) {
    // Handle non-string values
    if (value != null && typeof value !== 'string') {
      value = String(value);
    }
    
    value = value ? value.trim() : '';
    this._text = value;
    // Strip {!user=...} tags to plain text for content
    this._content = value.replace(/\{!user=(.*?)\}/g, '$1');
  }

  _checkDirect() {
    if (!this.me) return;

    const mePattern = this.me.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // Escape regex chars

    // Check if message ends with ", botname" or ". botname"
    const endPattern = new RegExp(`, ?${mePattern}[\\?\\!\\.\\s]*?$`, 'i');
    if (endPattern.test(this._text)) {
      this._text = this._text.replace(endPattern, '').trim();
      this._content = this._text.replace(/\{!user=(.*?)\}/g, '$1');
      this.is_direct = 1;
      return;
    }

    // Check if message starts with "botname:" or "botname," or "botname -"
    const startPattern = new RegExp(`^${mePattern}[\\:\\,\\- ]+`, 'i');
    if (startPattern.test(this._text)) {
      this._text = this._text.replace(startPattern, '').trim();
      this._content = this._text.replace(/\{!user=(.*?)\}/g, '$1');
      this.is_direct = 1;
      return;
    }

    // Check for "botname -- " format
    const dashPattern = new RegExp(`^${mePattern} \\-+ `, 'i');
    if (dashPattern.test(this._text)) {
      this._text = this._text.replace(dashPattern, '').trim();
      this._content = this._text.replace(/\{!user=(.*?)\}/g, '$1');
      this.is_direct = 1;
      return;
    }
  }

  isPrivate() {
    return this.me ? (this.to === this.me) : false;
  }

  reply(overrides = {}) {
    const replyMsg = new Message({
      from: this.me,
      to: this.reply_to || (this.isPrivate() ? this.from : this.to),
      me: this.me,
      content: '',
      ...overrides
    });
    return replyMsg;
  }

  clone() {
    return new Message({
      from: this.from,
      to: this.to,
      reply_to: this.reply_to,
      content: this.content,
      text: this._text,
      timestamp: this.timestamp,
      is_direct: this.is_direct,
      me: this.me,
      origin: this.origin,
      invisible: this.invisible
    });
  }
}

export default Message;
