import Command from './Command.js';
import https from 'https';

class Define extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.commandRegEx('^(.*)$', 'parseMessage');
  }

  async parseMessage(message, captures) {
    const phrase = captures[0];
    if (!phrase) return 'what';

    const def = await this._parse(phrase);
    
    if (def) {
      return def;
    }

    return `${message.from}: No definition for ${phrase}.`;
  }

  async _parse(phrase) {
    const sources = ['urbandictionary', 'wikipedia'];
    
    for (const source of sources) {
      const def = await this[source](phrase);
      if (def) {
        return def;
      }
    }
    
    return null;
  }

  async urbandictionary(phrase) {
    try {
      const url = `https://www.urbandictionary.com/define.php?term=${encodeURIComponent(phrase)}`;
      const content = await this._httpGet(url);
      
      if (!content) return null;

      const defMatch = content.match(/<div class=['"]meaning['"]>(.*?)<\/div>/is);
      if (!defMatch) return null;

      let def = defMatch[1];
      def = def.replace(/<sup>.*?<\/sup>/g, '');
      def = this._stripHtml(def);
      def = def.replace(/\s+/g, ' ').replace(/ ,/g, ',').trim();

      if (!def) return null;

      const firstSentence = def.match(/^[^.!?]+[.!?]/);
      if (firstSentence) {
        return firstSentence[0] + ' (UD)';
      }

      return def.substring(0, 200) + '... (UD)';
    } catch (err) {
      return null;
    }
  }

  async wikipedia(phrase) {
    try {
      const url = `https://en.wikipedia.org/wiki/Special:Search?search=${encodeURIComponent(phrase)}`;
      const content = await this._httpGet(url);
      
      if (!content) return null;

      let firstPMatch = content.match(/<p>(.*?)<\/p>/is);
      if (!firstPMatch) return null;

      let firstP = firstPMatch[1];
      firstP = firstP.replace(/<sup>.*?<\/sup>/g, '');
      firstP = this._stripHtml(firstP);

      if (!firstP || firstP.includes('may refer to:')) return null;
      if (firstP.includes('see Wikipedia:Searching') || firstP.includes('You may create the page')) {
        return null;
      }

      const firstSentence = firstP.match(/^[^.]+\./);
      if (firstSentence) {
        let def = firstSentence[0];
        def = def.replace(/\[\d+\]/g, '');
        def = def.replace(/\s+/g, ' ').replace(/ ,/g, ',').trim();
        def = def.replace(/\(help·info\)/g, '');
        def = def.replace(/\[[^\]]+\]/g, '');
        return def + ' (WP)';
      }

      return null;
    } catch (err) {
      return null;
    }
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

  _httpGet(url) {
    return new Promise((resolve, reject) => {
      https.get(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
        timeout: 10000
      }, (res) => {
        if (res.statusCode !== 200) {
          resolve(null);
          return;
        }

        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => resolve(data));
      }).on('error', () => resolve(null));
    });
  }

  help() {
    return [
      'Define looks up definitions from Urban Dictionary and Wikipedia.',
      'Usage: define <phrase>',
      'The bot will search multiple sources and return the first match found.'
    ];
  }
}

export default Define;
