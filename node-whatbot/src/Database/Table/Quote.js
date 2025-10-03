/**
 * Quote.js - Quote storage table
 * Matches Whatbot::Database::Table::Quote from Perl version
 */

import Table from './Table.js';

class Quote extends Table {
  constructor({ handle }) {
    super({ handle });
    
    this.initTable({
      name: 'quote',
      primary_key: 'quote_id',
      indexed: ['user', 'quoted'],
      defaults: {
        timestamp: { database: 'now' }
      },
      columns: {
        quote_id: {
          type: 'serial'
        },
        timestamp: {
          type: 'integer'
        },
        user: {
          type: 'varchar',
          size: 255
        },
        quoted: {
          type: 'varchar',
          size: 255
        },
        content: {
          type: 'text'
        }
      }
    });
  }

  create(columnData) {
    // Check for duplicate before creating
    const content = columnData.content;
    const existing = this.searchOne({ content });
    
    if (existing) {
      const error = new Error('Quote already exists');
      error.name = 'QuoteExistsError';
      error.user = existing.user;
      throw error;
    }
    
    return super.create(columnData);
  }

  getRandom(user = null) {
    const params = {
      _order_by: 'RANDOM()',
      _limit: 1
    };
    
    if (user) {
      params.quoted = { LIKE: user };
    }
    
    return this.searchOne(params);
  }
}

export default Quote;
