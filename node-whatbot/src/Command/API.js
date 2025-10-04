import Command from './Command.js';

class API extends Command {
  constructor(config) {
    super(config);
    this.seenIds = {};
  }

  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    if (this.myConfig && this.myConfig.enabled === 'yes') {
      if (this.ios && this.ios.Web) {
        this.ios.Web.addDispatch(this, '/api/message', this.message.bind(this));
        this.ios.Web.addDispatch(this, '/api/karma', this.karma.bind(this));
      }
    }
  }

  async message(req, res) {
    if (!this.checkAccess(req)) {
      return this._createContent('{"error":"Access denied"}');
    }

    const destination = req.body?.destination || req.query?.destination;
    const messageContent = req.body?.message || req.query?.message;
    const messageId = req.body?.message_id || req.query?.message_id;

    if (destination && messageContent) {
      if (messageId) {
        if (this.seenIds[messageId]) {
          return this._createContent('{"error":"Message ID already used"}');
        }
        this.seenIds[messageId] = 1;
      }

      this.log.write('*** Message sent from API');
      this.sendMessage(destination, {
        to: '',
        from: '',
        content: messageContent,
        invisible: true
      });

      return this._createContent('{"status":"ok"}');
    }

    return this._createContent('{"error":"Missing destination or message"}');
  }

  async karma(req, res) {
    if (!this.checkAccess(req)) {
      return this._createContent('{"error":"Access denied"}');
    }

    const subject = req.body?.subject || req.query?.subject;
    const set = req.body?.set || req.query?.set;
    const from = req.body?.from || req.query?.from;
    const messageId = req.body?.message_id || req.query?.message_id;

    if (subject && set && from) {
      if (messageId) {
        if (this.seenIds[messageId]) {
          return this._createContent('{"error":"Message ID already used"}');
        }
        this.seenIds[messageId] = 1;
      }

      if (set !== 'up' && set !== 'down') {
        return this._createContent('{"error":"set parameter must be up or down"}');
      }

      if (set === 'up') {
        await this.model('Karma').increment(subject, from);
      } else {
        await this.model('Karma').decrement(subject, from);
      }

      this.log.write(`*** Karma set from API: ${subject} set ${set}`);
      return this._createContent('{"status":"ok"}');
    }

    return this._createContent('{"error":"Missing subject, from, or set"}');
  }

  checkAccess(req) {
    if (!this.myConfig || this.myConfig.enabled !== 'yes') {
      return false;
    }

    if (this.myConfig.limit_ip) {
      if (req.ip !== this.myConfig.limit_ip) {
        return false;
      }
    }

    if (this.myConfig.token) {
      const token = req.body?.token || req.query?.token;
      if (token !== this.myConfig.token) {
        return false;
      }
    }

    return true;
  }

  _createContent(content) {
    return [200, 'OK', { 'Content-Type': 'application/json' }, content];
  }

  help() {
    if (this.myConfig && this.myConfig.enabled === 'yes') {
      return 'API endpoints available at /api/message and /api/karma';
    }
    return 'API is not enabled.';
  }
}

export default API;
