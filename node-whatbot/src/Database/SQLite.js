/**
 * SQLite.js - SQLite database handler
 * Matches Whatbot::Database::SQLite from Perl version
 */

import DatabaseLib from 'better-sqlite3';
import Database from './Database.js';

class SQLite extends Database {
  constructor() {
    super();
  }

  connect() {
    const dbPath = this.config().database.database;
    if (!dbPath) {
      throw new Error('SQLite requires a database path.');
    }

    this.log().write(`Connecting to SQLite database: ${dbPath}`);
    
    this.handle = new DatabaseLib(dbPath, {
      verbose: process.env.WB_DATABASE_DEBUG ? console.log : null
    });

    // Enable foreign keys
    this.handle.pragma('foreign_keys = ON');
    
    this.getTables();
  }

  disconnect() {
    if (this.handle) {
      this.handle.close();
      this.handle = null;
    }
  }

  getTables() {
    const stmt = this.handle.prepare("SELECT name FROM sqlite_master WHERE type='table'");
    const rows = stmt.all();
    
    this.tables = {};
    for (const row of rows) {
      this.tables[row.name] = 1;
    }
    
    return this.tables;
  }

  lastInsertId(tableName) {
    const stmt = this.handle.prepare('SELECT last_insert_rowid() as id');
    const row = stmt.get();
    return row.id;
  }

  serial(size) {
    this.postfix = true;
    return this.integer();
  }

  serialPostfix() {
    return 'AUTOINCREMENT';
  }

  now() {
    return Math.floor(Date.now() / 1000);
  }

  quote(value) {
    if (value === null || value === undefined) {
      return 'NULL';
    }
    if (typeof value === 'number') {
      return value.toString();
    }
    // Escape single quotes by doubling them (SQLite standard)
    return "'" + String(value).replace(/'/g, "''") + "'";
  }

  quoteIdentifier(name) {
    // SQLite uses double quotes for identifiers
    return '"' + String(name).replace(/"/g, '""') + '"';
  }
}

export default SQLite;
