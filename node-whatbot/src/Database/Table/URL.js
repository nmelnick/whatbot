import Table from './Table.js';
import https from 'https';
import http from 'http';

class URL extends Table {
  constructor() {
    super();
    
    this.initTable({
      name: 'url',
      primaryKey: 'url_id',
      defaults: {
        timestamp: { database: 'now' }
      },
      columns: {
        url_id: {
          type: 'serial'
        },
        timestamp: {
          type: 'integer'
        },
        protocol_id: {
          type: 'integer'
        },
        domain_id: {
          type: 'integer'
        },
        path: {
          type: 'varchar',
          size: 255
        },
        user: {
          type: 'varchar',
          size: 255
        },
        title: {
          type: 'varchar',
          size: 512
        }
      }
    });

    this.tableProtocol = new Table();
    this.tableProtocol.initTable({
      name: 'url_protocol',
      primaryKey: 'protocol_id',
      indexed: ['name'],
      columns: {
        protocol_id: {
          type: 'serial'
        },
        name: {
          type: 'varchar',
          size: 12
        }
      }
    });

    this.tableDomain = new Table();
    this.tableDomain.initTable({
      name: 'url_domain',
      primaryKey: 'domain_id',
      indexed: ['name'],
      defaults: {
        timestamp: { database: 'now' }
      },
      columns: {
        domain_id: {
          type: 'serial'
        },
        timestamp: {
          type: 'integer'
        },
        name: {
          type: 'varchar',
          size: 255
        }
      }
    });
  }

  async getProtocol(protocol) {
    let protocolRow = await this.tableProtocol.searchOne({ name: protocol });
    if (!protocolRow) {
      protocolRow = await this.tableProtocol.create({ name: protocol });
    }
    return protocolRow.protocol_id;
  }

  async getDomain(domain) {
    let domainRow = await this.tableDomain.searchOne({ name: domain });
    if (!domainRow) {
      domainRow = await this.tableDomain.create({ name: domain });
    }
    return domainRow.domain_id;
  }

  async urlAsync(url, from) {
    const urlObj = new globalThis.URL(url);
    const protocolId = await this.getProtocol(urlObj.protocol.replace(':', ''));
    const domainId = await this.getDomain(urlObj.hostname);

    const path = urlObj.pathname + (urlObj.search || '');

    let row = await this.searchOne({
      protocol_id: protocolId,
      domain_id: domainId,
      path: path
    });

    if (row) {
      return row;
    } else {
      const title = await this.retrieveUrlAsync(url);
      return await this.create({
        user: from,
        title: title,
        domain_id: domainId,
        protocol_id: protocolId,
        path: path
      });
    }
  }

  async urlTitleAsync(url, from) {
    const row = await this.urlAsync(url, from);
    let title = row.title;
    
    if (title && title.startsWith('! ')) {
      await row.delete();
    }
    
    return title;
  }

  async retrieveUrlAsync(url) {
    return new Promise((resolve) => {
      const client = url.startsWith('https') ? https : http;
      
      const options = {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        },
        timeout: 10000
      };

      const req = client.get(url, options, (res) => {
        if (res.statusCode >= 400) {
          if (res.statusCode === 401 || res.statusCode === 403) {
            resolve('! Authorization required');
          } else if (res.statusCode === 404) {
            resolve('! Not Found');
          } else {
            resolve(`! Error ${res.statusCode}`);
          }
          return;
        }

        const chunks = [];
        let size = 0;
        const maxSize = 5192;

        res.on('data', (chunk) => {
          size += chunk.length;
          if (size > maxSize) {
            req.destroy();
            return;
          }
          chunks.push(chunk);
        });

        res.on('end', () => {
          const content = Buffer.concat(chunks).toString();
          const title = this.parseUrlContent(url, res.headers['content-type'], content);
          resolve(title);
        });
      });

      req.on('error', (err) => {
        resolve('! Could not connect or resolve address');
      });

      req.on('timeout', () => {
        req.destroy();
        resolve('! Request timeout');
      });
    });
  }

  parseUrlContent(url, contentType, content) {
    if (contentType && contentType.startsWith('image/')) {
      return 'Image';
    }

    const titleMatch = content.match(/<title[^>]*>(.*?)<\/title>/is);
    if (titleMatch) {
      return titleMatch[1].trim().replace(/\s+/g, ' ');
    }

    return 'No parsable title';
  }
}

export default URL;
