/**
 * Database.js - Base database class
 * Matches Whatbot::Database from Perl version
 */

import Component from '../Component.js';

class Database extends Component {
  constructor() {
    super();
    this.handle = null;
    this.tables = {};
    this._postfix = false;
  }

  get postfix() {
    return this._postfix;
  }

  set postfix(value) {
    this._postfix = value;
  }

  connect() {
    throw new Error('connect() must be implemented by subclass');
  }

  disconnect() {
    throw new Error('disconnect() must be implemented by subclass');
  }

  getTables() {
    throw new Error('getTables() must be implemented by subclass');
  }

  lastInsertId(tableName) {
    throw new Error('lastInsertId() must be implemented by subclass');
  }

  // Type methods for schema creation
  integer(size) {
    return 'INTEGER';
  }

  varchar(size) {
    return size ? `VARCHAR(${size})` : 'VARCHAR(255)';
  }

  text(size) {
    return 'TEXT';
  }

  char(size) {
    return size ? `CHAR(${size})` : 'CHAR(255)';
  }

  serial(size) {
    throw new Error('serial() must be implemented by subclass');
  }

  timestamp(size) {
    return 'INTEGER';
  }

  now() {
    return Math.floor(Date.now() / 1000);
  }

  serialPostfix() {
    return '';
  }
}

export default Database;
