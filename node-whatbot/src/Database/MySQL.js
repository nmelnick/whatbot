/**
 * MySQL.js - MySQL database handler
 * Matches Whatbot::Database::MySQL from Perl version
 */

import Database from './Database.js';

class MySQL extends Database {
  constructor() {
    super();
    this.pool = null;
  }

  async connect() {
    const dbConfig = this.config().database;
    
    if (!dbConfig.database) {
      throw new Error('MySQL requires a database name.');
    }

    try {
      const mysql = await import('mysql2/promise');

      const config = {
        database: dbConfig.database,
        host: dbConfig.host || 'localhost',
        port: dbConfig.port || 3306,
        user: dbConfig.username || 'root',
        password: dbConfig.password || '',
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
        charset: 'utf8mb4'
      };

      this.pool = await mysql.default.createPool(config);
      
      // Test connection
      const connection = await this.pool.getConnection();
      this.handle = connection;
      
      this.log().write(`Connected to MySQL database: ${dbConfig.database}`);
      
      await this.getTables();
      
      connection.release();
    } catch (err) {
      if (err.code === 'ERR_MODULE_NOT_FOUND') {
        this.log().error('MySQL module not available. Install with: npm install mysql2');
        throw new Error('MySQL module not available');
      }
      throw err;
    }
  }

  async disconnect() {
    if (this.pool) {
      await this.pool.end();
      this.pool = null;
      this.handle = null;
    }
  }

  async getTables() {
    const connection = await this.pool.getConnection();
    try {
      const [rows] = await connection.query('SHOW TABLES');
      
      this.tables = {};
      for (const row of rows) {
        const tableName = Object.values(row)[0];
        this.tables[tableName] = 1;
      }
      
      return this.tables;
    } finally {
      connection.release();
    }
  }

  async lastInsertId(tableName) {
    const connection = await this.pool.getConnection();
    try {
      const [rows] = await connection.query('SELECT LAST_INSERT_ID() as id');
      return rows[0]?.id;
    } finally {
      connection.release();
    }
  }

  integer(size) {
    return size ? `INT(${size})` : 'INT';
  }

  serial(size) {
    return 'INT AUTO_INCREMENT';
  }

  serialPostfix() {
    return '';
  }

  random() {
    return 'RAND()';
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
    // MySQL escaping
    return "'" + String(value)
      .replace(/\\/g, '\\\\')
      .replace(/'/g, "\\'")
      .replace(/"/g, '\\"')
      .replace(/\n/g, '\\n')
      .replace(/\r/g, '\\r')
      .replace(/\x00/g, '\\0')
      .replace(/\x1a/g, '\\Z') + "'";
  }

  quoteIdentifier(name) {
    // MySQL uses backticks for identifiers
    return '`' + String(name).replace(/`/g, '``') + '`';
  }

  // Helper to get a connection from pool for queries
  async getConnection() {
    if (!this.pool) {
      throw new Error('Database not connected');
    }
    return await this.pool.getConnection();
  }

  // Execute a query with automatic connection handling
  async query(sql, params = []) {
    const connection = await this.getConnection();
    try {
      const [rows] = await connection.query(sql, params);
      return rows;
    } finally {
      connection.release();
    }
  }

  // For prepared statements (parameterized queries)
  prepare(sql) {
    return {
      all: async (params = []) => {
        return await this.query(sql, params);
      },
      get: async (params = []) => {
        const rows = await this.query(sql, params);
        return rows[0] || null;
      },
      run: async (params = []) => {
        const connection = await this.getConnection();
        try {
          const [result] = await connection.query(sql, params);
          return {
            changes: result.affectedRows,
            lastInsertRowid: result.insertId
          };
        } finally {
          connection.release();
        }
      }
    };
  }
}

export default MySQL;
