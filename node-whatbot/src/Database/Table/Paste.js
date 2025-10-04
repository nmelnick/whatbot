import Table from './Table.js';

class Paste extends Table {
  constructor() {
    super();
    
    this.initTable({
      name: 'paste',
      primary_key: 'paste_id',
      indexed: ['user', 'destination'],
      defaults: {
        timestamp: { database: 'now' }
      },
      columns: {
        paste_id: {
          type: 'serial'
        },
        timestamp: {
          type: 'integer'
        },
        user: {
          type: 'varchar',
          size: 255
        },
        destination: {
          type: 'varchar',
          size: 255
        },
        summary: {
          type: 'text'
        },
        content: {
          type: 'text'
        }
      }
    });
  }
}

export default Paste;
