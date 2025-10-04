/**
 * Row.js - Database table row wrapper
 * Matches Whatbot::Database::Table::Row from Perl version
 */

class Row {
  constructor({ primary_key, table, columns, column_data, handle }) {
    this.primaryKey = primary_key;
    this.tableName = table;
    this.columns = columns;
    this.columnData = column_data;
    this.handle = handle;

    // Create accessors for each column
    for (let i = 0; i < columns.length; i++) {
      const columnName = columns[i];
      const camelName = this._toCamelCase(columnName);
      
      Object.defineProperty(this, camelName, {
        get: () => this.columnData[i],
        set: (value) => { this.columnData[i] = value; },
        enumerable: true
      });
    }
  }

  _toCamelCase(str) {
    // Convert snake_case to camelCase but also support direct column names
    return str.replace(/_([a-z])/g, (m, p1) => p1.toUpperCase());
  }

  save() {
    if (!this.handle || !this.primaryKey) {
      throw new Error('Cannot save row: missing handle or primary key');
    }

    const updates = [];
    const values = [];
    
    for (let i = 0; i < this.columns.length; i++) {
      const col = this.columns[i];
      if (col !== this.primaryKey) {
        updates.push(`"${col}" = ?`);
        values.push(this.columnData[i]);
      }
    }

    const primaryKeyIndex = this.columns.indexOf(this.primaryKey);
    const primaryKeyValue = this.columnData[primaryKeyIndex];
    values.push(primaryKeyValue);

    const query = `UPDATE "${this.tableName}" SET ${updates.join(', ')} WHERE "${this.primaryKey}" = ?`;
    const stmt = this.handle.prepare(query);
    stmt.run(...values);
  }

  delete() {
    if (!this.handle || !this.primaryKey) {
      throw new Error('Cannot delete row: missing handle or primary key');
    }

    const primaryKeyIndex = this.columns.indexOf(this.primaryKey);
    const primaryKeyValue = this.columnData[primaryKeyIndex];

    const query = `DELETE FROM "${this.tableName}" WHERE "${this.primaryKey}" = ?`;
    const stmt = this.handle.prepare(query);
    stmt.run(primaryKeyValue);
  }

  // Access column data by index (for compatibility with Perl version)
  get column_data() {
    return this.columnData;
  }
}

export default Row;
