/**
 * PostgreSQL.js - PostgreSQL database handler
 * Matches Whatbot::Database::PostgreSQL from Perl version
 */

import Database from './Database.js';

class PostgreSQL extends Database {
  constructor() {
    super();
    this.pool = null;
  }

  async connect() {
    const dbConfig = this.config().database;
    
    if (!dbConfig.database) {
      throw new Error('PostgreSQL requires a database name.');
    }

    try {
      const pg = await import('pg');
      const { Pool } = pg.default;

      const config = {
        database: dbConfig.database,
        host: dbConfig.host || 'localhost',
        port: dbConfig.port || 5432,
        user: dbConfig.username || 'postgres',
        password: dbConfig.password || '',
        max: 20,
        idleTimeoutMillis: 30000,
        connectionTimeoutMillis: 2000,
      };

      this.pool = new Pool(config);
      
      // Test connection
      const client = await this.pool.connect();
      this.handle = client;
      
      this.log().write(`Connected to PostgreSQL database: ${dbConfig.database}`);
      
      await this.getTables();
      
      client.release();
    } catch (err) {
      if (err.code === 'ERR_MODULE_NOT_FOUND') {
        this.log().error('PostgreSQL module not available. Install with: npm install pg');
        throw new Error('PostgreSQL module not available');
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
    const client = await this.pool.connect();
    try {
      const result = await client.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public'
      `);
      
      this.tables = {};
      for (const row of result.rows) {
        this.tables[row.table_name] = 1;
      }
      
      return this.tables;
    } finally {
      client.release();
    }
  }

  async lastInsertId(tableName) {
    // PostgreSQL uses RETURNING clause or currval on sequences
    // This is typically handled in the create() method of Table
    const client = await this.pool.connect();
    try {
      const result = await client.query(`
        SELECT currval(pg_get_serial_sequence($1, $2)) as id
      `, [tableName, tableName + '_id']);
      
      return result.rows[0]?.id;
    } catch (err) {
      // If sequence doesn't exist, return null
      return null;
    } finally {
      client.release();
    }
  }

  serial(size) {
    return 'SERIAL';
  }

  serialPostfix() {
    return '';
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
    // PostgreSQL uses dollar quoting or escaped single quotes
    return "'" + String(value).replace(/'/g, "''") + "'";
  }

  quoteIdentifier(name) {
    // PostgreSQL uses double quotes for identifiers (case-sensitive)
    return '"' + String(name).replace(/"/g, '""') + '"';
  }

  // Helper to get a client from pool for queries
  async getClient() {
    if (!this.pool) {
      throw new Error('Database not connected');
    }
    return await this.pool.connect();
  }

  // Execute a query with automatic client handling
  async query(sql, params = []) {
    const client = await this.getClient();
    try {
      return await client.query(sql, params);
    } finally {
      client.release();
    }
  }

  // For prepared statements (parameterized queries)
  prepare(sql) {
    return {
      all: async (params = []) => {
        const result = await this.query(sql, params);
        return result.rows;
      },
      get: async (params = []) => {
        const result = await this.query(sql, params);
        return result.rows[0] || null;
      },
      run: async (params = []) => {
        const result = await this.query(sql, params);
        return {
          changes: result.rowCount,
          lastInsertRowid: result.rows[0]?.id
        };
      }
    };
  }
}

export default PostgreSQL;
