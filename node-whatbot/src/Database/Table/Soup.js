import Table from './Table.js';

class Soup extends Table {
  constructor() {
    super();
    
    this.initTable({
      name: 'soup',
      primary_key: 'soup_id',
      indexed: ['module_id', 'subject'],
      columns: {
        soup_id: {
          type: 'serial'
        },
        module_id: {
          type: 'integer'
        },
        subject: {
          type: 'varchar',
          size: 255
        },
        value: {
          type: 'text'
        }
      }
    });

    this.module = null;
  }

  async init() {
    await super.init?.();
    
    // Create module sub-table with database reference
    this.module = new Table();
    this.module._database = this._database;
    
    this.module.initTable({
      name: 'soup_module',
      primary_key: 'module_id',
      indexed: ['name'],
      columns: {
        module_id: {
          type: 'serial'
        },
        name: {
          type: 'varchar',
          size: 255
        }
      }
    });
  }

  async _ensureModuleTable() {
    if (!this.module) {
      this.module = new Table();
      this.module._database = this._database;
      
      this.module.initTable({
        name: 'soup_module',
        primary_key: 'module_id',
        indexed: ['name'],
        columns: {
          module_id: {
            type: 'serial'
          },
          name: {
            type: 'varchar',
            size: 255
          }
        }
      });
    }
  }

  async _getModule(caller) {
    await this._ensureModuleTable();
    
    let module = await this.module.searchOne({ name: caller });
    if (module) {
      return module.moduleId;
    } else {
      module = await this.module.create({ name: caller });
      return module ? module.moduleId : null;
    }
  }

  async set(key, value, caller) {
    const moduleId = await this._getModule(caller);
    let row = await this.searchOne({
      module_id: moduleId,
      subject: key
    });
    
    if (row) {
      row.value = value;
      await row.save();
    } else {
      row = await this.create({
        module_id: moduleId,
        subject: key,
        value: value
      });
    }
    
    return row ? row.value : null;
  }

  async get(key, caller) {
    const moduleId = await this._getModule(caller);
    const row = await this.searchOne({
      module_id: moduleId,
      subject: key
    });
    
    if (row) {
      return row.value;
    }
    return null;
  }

  async clear(key, caller) {
    const moduleId = await this._getModule(caller);
    const row = await this.searchOne({
      module_id: moduleId,
      subject: key
    });
    
    if (row) {
      await row.delete();
    }
  }

  async getHashref(caller) {
    await this._ensureModuleTable();
    const moduleId = await this._getModule(caller);
    const rows = await this.search({
      module_id: moduleId
    });
    
    const results = {};
    for (const row of rows) {
      results[row.subject] = row.value;
    }
    return results;
  }

  async getCount(caller) {
    const moduleId = await this._getModule(caller);
    return await this.count({
      module_id: moduleId
    });
  }
}

export default Soup;
