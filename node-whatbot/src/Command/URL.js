import Command from './Command.js';

class URLCommand extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.globalRegEx(/.*?((https|http|ftp|feed):\/\/[^\s]+).*/, 'storeUrl');
    this.command('last');
    this.command('count');
    this.command('search');
  }

  async storeUrl(message, captures) {
    if (message.invisible) return null;

    let url = captures[0];
    url = url.replace(/\|.*/, '');

    const title = await this.model('URL').urlTitleAsync(url, message.from);
    
    if (title && !title.startsWith('! ')) {
      return {
        from: 'me',
        to: 'public',
        content: `[URL: ${title}]`,
        invisible: true
      };
    }

    return null;
  }

  async last(message) {
    const row = await this.model('URL').searchOne({}, { _order_by: 'url_id DESC' });
    
    if (row) {
      const urlDomain = await this.model('URL').tableDomain.find(row.domainId);
      const urlProtocol = await this.model('URL').tableProtocol.find(row.protocolId);
      
      const date = new Date(row.timestamp * 1000);
      const dateStr = date.toISOString().split('T')[0] + ' at ' + 
                      date.toTimeString().split(' ')[0].substring(0, 5);
      
      return [
        `[URL: ${urlProtocol.name}://${urlDomain.name}/${row.path}]`,
        `(From ${row.user} on ${dateStr} - "${row.title}")`
      ];
    }

    return 'No URLs found.';
  }

  async count(message) {
    const urls = await this.model('URL').count();
    const domains = await this.model('URL').tableDomain.count();
    
    return `There are ${urls} URLs attached to ${domains} domains stored.`;
  }

  async search(message, captures) {
    const searchText = captures.join(' ');
    if (!searchText) return null;

    const results = await this.model('URL').search({
      title: { LIKE: `%${searchText}%` }
    });

    const response = [];
    
    if (results.length > 3) {
      response.push(`There were ${results.length} result(s) found, showing the first 3.`);
    }

    for (let i = 0; i < Math.min(3, results.length); i++) {
      const row = results[i];
      const urlDomain = await this.model('URL').tableDomain.find(row.domainId);
      const urlProtocol = await this.model('URL').tableProtocol.find(row.protocolId);
      
      response.push(
        `${i + 1}) ${urlProtocol.name}://${urlDomain.name}${row.path} - "${row.title}"`
      );
    }

    return response.length > 0 ? response : `No results for "${searchText}" found.`;
  }

  help() {
    return [
      'URL is a URL management module for whatbot. All canonical URLs seen ' +
      'in any open channels or chats are stored with the title of the found ' +
      'page, user information, and timestamp. To query URLs, start the ' +
      'command with "url" and then one of the following: ',
      ' * "last" to show the last URL given, along with the user, title and time.',
      ' * "search" (text) to search titles of past URLs.'
    ];
  }
}

export default URLCommand;
