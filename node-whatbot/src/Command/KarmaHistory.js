import Command from './Command.js';

class KarmaHistory extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.globalRegEx(/^(\w+) (like|hate)s what/i, 'random');
    this.globalRegEx(/^[\. ]*?fightin(?:'|g)? words\??$/i, 'controversy');
    this.globalRegEx(/^[\. ]*?what(?: is|'s)(?: the)? (best|worst)/i, 'superlative');
    this.globalRegEx(/^[\. ]*?who (hates|likes|loves|doesn't like|plussed|minused) (.*)/i, 'parseMessage');
  }

  async random(message, captures) {
    const [who, verb] = captures;
    const from = message.from;
    const op = verb.toLowerCase() === 'like' ? 1 : -1;

    const nick = await this.model('UserAlias').canonicalUser(who.toLowerCase());

    const query = `
      SELECT subject, amount FROM karma WHERE 
        amount = ${op} AND
        user LIKE '${nick}' AND
        subject NOT IN (SELECT subject FROM karma WHERE amount = ${op} and user NOT LIKE '${nick}')
    `;

    const karmas = await this.database.handle.all(query);

    if (!karmas || karmas.length === 0) {
      return `${who} doesn't ${verb} anything weird. that I know of.`;
    }

    const karma = karmas[Math.floor(Math.random() * karmas.length)];
    const asNick = who !== nick ? ` (as ${nick})` : '';

    return `${who}${asNick} ${verb}s ${karma.subject}.`;
  }

  async controversy(message) {
    const limit = 10;

    const query = `
      SELECT subject, votes - votesum as score 
      FROM (
        SELECT subject, sum(amount) as votesum, sum(abs(amount)) as votes 
        FROM karma 
        GROUP BY subject
      ) 
      ORDER BY score DESC 
      LIMIT ${limit}
    `;

    const rows = await this.database.handle.all(query);

    if (!rows || rows.length === 0) {
      return 'No controversial topics found.';
    }

    const stuff = rows.map(row => `${row.subject} (${row.score})`);
    return stuff.join(', ');
  }

  async superlative(message, captures) {
    const best = captures[0].toLowerCase() === 'best';
    const limit = 10;

    const sort = best ? 'DESC' : 'ASC';
    const query = `
      SELECT subject, total 
      FROM (
        SELECT subject, sum(amount) as total 
        FROM karma 
        GROUP BY subject
      ) 
      ORDER BY total ${sort} 
      LIMIT ${limit}
    `;

    const rows = await this.database.handle.all(query);

    if (!rows || rows.length === 0) {
      return `No ${best ? 'best' : 'worst'} items found.`;
    }

    const stuff = rows.map(row => `${row.subject} (${row.total})`);
    return `The ${best ? 'best' : 'worst'} of everything is: ${stuff.join(', ')}`;
  }

  async parseMessage(message, captures) {
    if (!captures) return null;

    const what = captures[0];
    let subject = captures[1].toLowerCase();
    
    subject = subject.replace(/[\.\?\! ]+$/, '');
    subject = subject.replace(/^(the|a|an) /, '');
    
    const nick = await this.model('UserAlias').canonicalUser(subject);

    const sort = (what === 'hates' || what === 'minused' || what === "doesn't like") ? 'ASC' : 'DESC';
    const op = (what === 'hates' || what === 'minused' || what === "doesn't like") ? '-1' : '1';

    const query = `
      SELECT user, total 
      FROM (
        SELECT user, sum(amount) as total 
        FROM karma 
        WHERE subject = '${nick}' AND amount = ${op} 
        GROUP BY user
      ) 
      ORDER BY total ${sort}
    `;

    const people = await this.database.handle.all(query);

    const asNick = subject !== nick ? `(as ${nick}) ` : '';

    if (people.length === 1) {
      const num = Math.abs(people[0].total);
      const who = people[0].user;

      const howmuch = num === 1 ? 'once' : num === 2 ? 'twice' : `${num} times`;

      if (who === message.from) {
        return `${message.from}: ${asNick}It was YOU! ${howmuch.charAt(0).toUpperCase() + howmuch.slice(1)}.`;
      } else {
        return `${message.from}: ${asNick}It was ${who}, ${howmuch}.`;
      }
    } else if (people.length > 0) {
      const peopleText = people.map(p => `${p.user} (${p.total})`).join(', ');
      const sum = people.reduce((acc, p) => acc + p.total, 0);
      return `${message.from}: ${asNick}${peopleText} = ${sum}`;
    } else {
      return `${message.from}: Nobody!`;
    }
  }

  help() {
    return [
      'KarmaHistory provides karma-based queries.',
      'Commands:',
      ' * "<user> likes what" - Show what a user likes uniquely',
      ' * "<user> hates what" - Show what a user hates uniquely',
      ' * "fighting words" - Show most controversial topics',
      ' * "what is the best/worst" - Show top/bottom karma items',
      ' * "who likes/hates <subject>" - Show who likes/hates something'
    ];
  }
}

export default KarmaHistory;
