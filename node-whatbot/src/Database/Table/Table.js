/**
 * Table.js - Database table base class
 * Matches Whatbot::Database::Table from Perl version
 */

import Database from '../Database.js';
import Row from './Row.js';

class Table extends Database {
  constructor({ handle } = {}) {
    super();
    this._handle = handle;
    this.tableName = null;
    this.primaryKey = null;
    this.columns = [];
    this.defaults = {};
  }

  get handle() {
    return this._handle;
  }

  set handle(h) {
    this._handle = h;
  }

  initTable(tableData) {
    if (!tableData.name) {
      throw new Error('Missing name for table');
    }
    if (!tableData.columns) {
      throw new Error('Missing column data for table');
    }

    this.tableName = tableData.name;
    this.primaryKey = tableData.primary_key || null;
    this.columns = Object.keys(tableData.columns);
    this.defaults = tableData.defaults || {};

    // Create table if it doesn't exist
    if (!this.database().tables[tableData.name]) {
      this.log().write(`Creating table "${tableData.name}" for ${this.constructor.name}.`);
      this._makeTable(tableData);
    }
  }

  _makeTable(tableData) {
    const db = this.database();
    let query = `CREATE TABLE "${tableData.name}" (`;
    
    const localColumns = { ...tableData.columns };
    
    // Primary Key
    if (tableData.primary_key) {
      const columnData = localColumns[tableData.primary_key];
      if (!columnData) {
        throw new Error('Primary key specified but not given in column data.');
      }
      
      const type = columnData.type;
      const typeStr = db[type](columnData.size);
      const postfix = (type === 'serial' && db.postfix) ? db.serialPostfix() : '';
      
      query += `"${tableData.primary_key}" ${typeStr} PRIMARY KEY ${postfix}, `;
      delete localColumns[tableData.primary_key];
    }

    // Other Columns
    for (const [columnName, columnData] of Object.entries(localColumns)) {
      const type = columnData.type;
      const typeStr = db[type](columnData.size);
      query += `"${columnName}" ${typeStr}, `;
    }

    // Close Query
    query = query.slice(0, -2) + ')';
    
    if (process.env.WB_DATABASE_DEBUG) {
      this.log().write(query);
    }

    db.handle.prepare(query).run();

    // Create Indexes
    if (tableData.indexed) {
      for (const indexedColumn of tableData.indexed) {
        const indexName = `idx_${tableData.name}_${indexedColumn}`;
        const indexQuery = `CREATE INDEX "${indexName}" ON "${tableData.name}" ("${indexedColumn}")`;
        db.handle.prepare(indexQuery).run();
      }
    }

    db.getTables();
  }

  create(columnData) {
    const params = { ...this.defaults };
    
    for (const [key, value] of Object.entries(columnData)) {
      params[key] = value;
    }

    // Process special default values
    const processedParams = {};
    for (const [key, value] of Object.entries(params)) {
      if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
        if (value.database === 'now') {
          processedParams[key] = this.database().now();
        }
      } else {
        processedParams[key] = value;
      }
    }

    const columns = Object.keys(processedParams);
    const placeholders = columns.map(() => '?').join(', ');
    const columnNames = columns.map(c => `"${c}"`).join(', ');
    
    const query = `INSERT INTO "${this.tableName}" (${columnNames}) VALUES (${placeholders})`;
    
    if (process.env.WB_DATABASE_DEBUG) {
      this.log().write(query);
    }

    const values = columns.map(c => processedParams[c]);
    const stmt = this.database().handle.prepare(query);
    stmt.run(...values);

    return this.find(this.database().lastInsertId(this.tableName));
  }

  find(keyId) {
    if (!this.primaryKey) {
      throw new Error('Cannot find without primary key');
    }
    return this.searchOne({ [this.primaryKey]: keyId });
  }

  count(searchData = {}) {
    searchData._select = 'COUNT(*) AS column_1';
    const result = this.search(searchData);
    return result[0]?.columnData[0] || 0;
  }

  search(searchData = {}) {
    const columns = [];
    const query = this._generateQuery(searchData, columns);
    
    const stmt = this.database().handle.prepare(query);
    const rows = stmt.all();
    
    const results = [];
    for (const row of rows) {
      const columnData = searchData._select
        ? Object.values(row)
        : columns.map(c => row[c]);
      
      results.push(new Row({
        primary_key: this.primaryKey,
        table: this.tableName,
        columns: columns,
        column_data: columnData,
        handle: this.database().handle
      }));
    }
    
    return results;
  }

  searchOne(searchData = {}) {
    const rows = this.search(searchData);
    return rows.length > 0 ? rows[0] : null;
  }

  _generateQuery(searchData, columns) {
    let query = 'SELECT ';
    
    if (searchData._select) {
      query += searchData._select;
      const selectParts = searchData._select.split(',').map(s => s.trim());
      for (let i = 0; i < selectParts.length; i++) {
        columns.push(`column_${i + 1}`);
      }
    } else {
      columns.push(...this.columns);
      query += columns.map(c => `"${c}"`).join(', ');
    }
    
    query += ` FROM "${this.tableName}"`;
    
    const wheres = [];
    for (const [column, value] of Object.entries(searchData)) {
      if (column.startsWith('_')) continue;
      
      if (typeof value === 'object' && value !== null) {
        if (value.LIKE !== undefined) {
          wheres.push(`"${column}" LIKE ${this.database().quote(value.LIKE)}`);
        }
        if (value['>'] !== undefined) {
          wheres.push(`"${column}" > ${this.database().quote(value['>'])}`);
        }
        if (value['<'] !== undefined) {
          wheres.push(`"${column}" < ${this.database().quote(value['<'])}`);
        }
      } else {
        wheres.push(`"${column}" = ${this.database().quote(value)}`);
      }
    }
    
    if (wheres.length > 0) {
      query += ' WHERE ' + wheres.join(' AND ');
    }
    
    if (searchData._order_by) {
      query += ' ORDER BY ' + searchData._order_by;
    }
    
    if (searchData._limit) {
      query += ' LIMIT ' + searchData._limit;
    }
    
    if (process.env.WB_DATABASE_DEBUG) {
      this.log().write(query);
    }
    
    return query;
  }
}

export default Table;
