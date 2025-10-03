/**
 * Seen.js - Seen tracking table
 * Matches Whatbot::Database::Table::Seen from Perl version
 */

import Table from './Table.js';

class Seen extends Table {
  constructor({ handle }) {
    super({ handle });
    
    this.initTable({
      name: 'seen',
      primary_key: 'seen_id',
      indexed: ['user'],
      defaults: {
        timestamp: { database: 'now' }
      },
      columns: {
        seen_id: {
          type: 'serial'
        },
        timestamp: {
          type: 'integer'
        },
        user: {
          type: 'varchar',
          size: 255
        },
        message: {
          type: 'text'
        }
      }
    });
  }

  seen(user, message = null) {
    user = user.toLowerCase();
    
    const seenRow = this.searchOne({ user });
    
    if (message !== null) {
      // Store new seen message
      if (seenRow) {
        seenRow.delete();
      }
      return this.create({
        user: user,
        message: message
      });
    }

    return seenRow;
  }
}

export default Seen;
