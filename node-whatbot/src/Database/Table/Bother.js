import Table from './Table.js';

class Bother extends Table {
  constructor() {
    super();
    
    this.initTable({
      name: 'bother',
      primary_key: 'bother_id',
      indexed: ['user'],
      defaults: {
        timestamp: { database: 'now' },
        acknowledged: 0
      },
      columns: {
        bother_id: {
          type: 'serial'
        },
        timestamp: {
          type: 'integer'
        },
        user: {
          type: 'varchar',
          size: 255
        },
        about: {
          type: 'text'
        },
        every: {
          type: 'integer'
        },
        origin: {
          type: 'varchar',
          size: 255
        },
        acknowledged: {
          type: 'integer'
        }
      }
    });
  }

  async add(user, about, every, origin) {
    return await this.create({
      user: user,
      about: about,
      every: every,
      origin: origin
    });
  }

  async acknowledge(user, about) {
    const object = await this.searchOne({
      user: user,
      about: about
    });
    
    if (object) {
      object.acknowledged = Math.floor(Date.now() / 1000);
      await object.save();
      return true;
    }
    
    return false;
  }

  async acknowledgeAllFor(user) {
    const bothers = await this.getActiveFor(user);
    for (const bother of bothers) {
      await this.acknowledge(bother.user, bother.about);
    }
    return bothers;
  }

  async getActive() {
    return await this.search({
      acknowledged: { '<': 1 }
    });
  }

  async getActiveFor(user) {
    return await this.search({
      user: user,
      acknowledged: { '<': 1 }
    });
  }

  async get(user, about) {
    return await this.searchOne({
      user: user,
      about: about
    });
  }
}

export default Bother;
