import Log from '../Log.js';

class Infobot extends Log {
  parseLine(line) {
    const match = line.match(/^(\d+) \[\d+\] <(.*?)\/(.*?)> (.*)/);
    
    if (match) {
      const [, timestamp, user, channel, messageText] = match;
      
      if (!user || messageText.startsWith('!')) {
        return;
      }
      
      let content = messageText
        .replace(/\\what/g, 'what')
        .replace(/\\is/g, 'is');
      
      const message = this.getNewMessage({
        from: user,
        to: channel,
        content: content,
        timestamp: parseInt(timestamp),
        me: this.me
      });
      
      this.eventMessage(message);
    }
  }
}

export default Infobot;
