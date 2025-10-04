/**
 * UserAlias.js - User alias tracking table
 * Matches Whatbot::Database::Table::UserAlias from Perl version
 */

import Table from './Table.js';

class UserAlias extends Table {
  constructor({ handle }) {
    super({ handle });
    
    this.initTable({
      name: 'user_alias',
      primary_key: 'user_alias_id',
      indexed: ['user'],
      columns: {
        user_alias_id: {
          type: 'serial'
        },
        user: {
          type: 'varchar',
          size: 255
        },
        alias: {
          type: 'varchar',
          size: 255
        }
      }
    });
  }

  alias(user, alias) {
    user = user.toLowerCase();
    alias = alias.toLowerCase();
    if (!alias) return null;

    const row = this.searchOne({
      user: user,
      alias: alias
    });

    if (!row) {
      return this.create({
        user: user,
        alias: alias
      });
    }

    return null;
  }

  userForAlias(alias) {
    const row = this.searchOne({
      alias: alias
    });
    return row ? row.user : null;
  }

  aliasesForUser(user) {
    const rows = this.search({
      user: user
    });
    return rows.length > 0 ? rows.map(r => r.alias) : null;
  }

  relatedUsers(userOrAlias) {
    const users = [];
    
    const aliases = this.aliasesForUser(userOrAlias);
    if (aliases) {
      users.push(...aliases);
    }
    
    const user = this.userForAlias(userOrAlias);
    if (user) {
      users.push(user);
    }
    
    return users;
  }

  canonicalUser(user) {
    const lcUser = user.toLowerCase();
    return this.userForAlias(lcUser) || user;
  }

  remove(user, alias = null) {
    user = user.toLowerCase();
    
    if (alias) {
      alias = alias.toLowerCase();
      const row = this.searchOne({
        user: user,
        alias: alias
      });
      if (row) {
        row.delete();
        return true;
      }
    } else {
      const rows = this.search({
        user: user
      });
      if (rows.length > 0) {
        for (const row of rows) {
          row.delete();
        }
        return true;
      }
    }
    
    return false;
  }
}

export default UserAlias;
