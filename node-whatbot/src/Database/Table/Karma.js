/**
 * Karma.js - Karma table
 * Matches Whatbot::Database::Table::Karma from Perl version
 */

import Table from './Table.js';

class Karma extends Table {
  constructor({ handle }) {
    super({ handle });
    
    this.initTable({
      name: 'karma',
      primary_key: 'karma_id',
      indexed: ['subject', 'user'],
      defaults: {
        created: { database: 'now' }
      },
      columns: {
        karma_id: {
          type: 'serial'
        },
        subject: {
          type: 'varchar',
          size: 255
        },
        user: {
          type: 'varchar',
          size: 255
        },
        created: {
          type: 'integer'
        },
        amount: {
          type: 'integer'
        }
      }
    });
  }

  increment(topic, user) {
    return this.create({
      subject: topic,
      user: user,
      amount: 1
    });
  }

  decrement(topic, user) {
    return this.create({
      subject: topic,
      user: user,
      amount: -1
    });
  }

  get(topic) {
    const row = this.searchOne({
      _select: 'SUM(amount)',
      subject: topic.toLowerCase()
    });
    return row ? row.columnData[0] || 0 : 0;
  }

  getExtended(topic) {
    const incrementRow = this.searchOne({
      _select: 'COUNT(amount)',
      subject: topic,
      amount: 1
    });
    
    const decrementRow = this.searchOne({
      _select: 'COUNT(amount)',
      subject: topic,
      amount: -1
    });
    
    const lastRow = this.searchOne({
      subject: topic,
      _order_by: 'karma_id DESC',
      _limit: 1
    });

    if (!lastRow) {
      return null;
    }

    return {
      Increments: incrementRow?.columnData[0] || 0,
      Decrements: decrementRow?.columnData[0] || 0,
      Last: [
        lastRow.user,
        lastRow.amount
      ]
    };
  }

  topN(user, n) {
    return this._topBottomN(user, n, true);
  }

  bottomN(user, n) {
    return this._topBottomN(user, n, false);
  }

  _topBottomN(user, n, isTop) {
    const order = isTop ? 'DESC' : 'ASC';
    const query = `
      SELECT subject, sum FROM (
        SELECT subject, SUM(amount) AS sum FROM karma WHERE user LIKE '${user}'
        GROUP BY subject
      )
      ORDER BY sum ${order}
      LIMIT ${n}
    `;
    
    const stmt = this.database().handle.prepare(query);
    return stmt.all();
  }
}

export default Karma;
