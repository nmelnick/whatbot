/**
 * Factoid.js - Factoid table (the core of whatbot!)
 * Matches Whatbot::Database::Table::Factoid from Perl version
 */

import crypto from 'crypto';
import Table from './Table.js';

class Factoid extends Table {
  constructor({ handle }) {
    super({ handle });
    
    // Main factoid table
    this.initTable({
      name: 'factoid',
      primary_key: 'factoid_id',
      indexed: ['subject'],
      defaults: {
        created: { database: 'now' },
        updated: { database: 'now' }
      },
      columns: {
        factoid_id: {
          type: 'serial'
        },
        is_or: {
          type: 'integer'
        },
        is_plural: {
          type: 'integer'
        },
        created: {
          type: 'integer'
        },
        updated: {
          type: 'integer'
        },
        silent: {
          type: 'integer'
        },
        subject: {
          type: 'varchar',
          size: 255
        }
      }
    });

    // Description table (many descriptions per factoid)
    this.tableDescription = new Table({ handle });
    this.tableDescription.initTable({
      name: 'factoid_description',
      primary_key: 'hash',
      indexed: ['user', 'factoid_id'],
      defaults: {
        updated: { database: 'now' }
      },
      columns: {
        hash: {
          type: 'char',
          size: 40
        },
        factoid_id: {
          type: 'integer'
        },
        updated: {
          type: 'integer'
        },
        user: {
          type: 'varchar',
          size: 255
        },
        description: {
          type: 'text'
        }
      }
    });

    // Ignore table (blacklist)
    this.tableIgnore = new Table({ handle });
    this.tableIgnore.initTable({
      name: 'factoid_ignore',
      primary_key: 'subject',
      columns: {
        subject: {
          type: 'varchar',
          size: 255
        }
      }
    });
  }

  isSilent(subject) {
    subject = subject.toLowerCase();
    
    const factoid = this.searchOne({ subject });
    if (factoid) {
      return factoid.silent;
    }
    
    return null;
  }

  toggleSilence(subject) {
    subject = subject.toLowerCase();
    
    const factoid = this.searchOne({ subject });
    if (factoid) {
      if (factoid.silent) {
        factoid.silent = 0;
      } else {
        factoid.silent = 1;
      }
      factoid.save();
    }
    
    return this.isSilent(subject);
  }

  factoid(subject, is = null, from = null, plural = null) {
    const original = subject;
    subject = subject.toLowerCase();

    // Get existing factoid info, if available
    let factoid = this.searchOne({ subject });
    
    if (!factoid && !is) {
      return null;
    }

    // Assign fact info if defined
    if (is) {
      // Nuke all factoids if user says no
      if (subject.match(/^no, /i)) {
        subject = subject.replace(/^no, /i, '');
        this.forget(subject);
      }

      if (!factoid) {
        // Check if ignore
        if (this.ignore(subject)) {
          return null;
        }

        // Check if plural
        const isPlural = plural ? 1 : 0;

        this.create({
          is_or: 0,
          is_plural: isPlural,
          created: Math.floor(Date.now() / 1000),
          updated: Math.floor(Date.now() / 1000),
          subject: subject
        });

        factoid = this.searchOne({ subject });
      }

      // Remove "also" because we don't care
      is = is.replace(/^also /, '');

      // Nuke <reply> if not or and more than one fact
      if (is.match(/^<reply>/)) {
        const factoidCount = this.tableDescription.count({
          factoid_id: factoid.factoidId
        });
        if (factoidCount > 0 && !(factoid.isOr && factoid.isOr == 1)) {
          return null;
        }
      }

      // Nuke response if we already have a reply
      const firstFact = this.tableDescription.searchOne({
        factoid_id: factoid.factoidId
      });
      if (firstFact && firstFact.description.match(/^<reply>/)) {
        return null;
      }

      // Don't bother if this exact factoid combo exists
      const hash = crypto.createHash('sha1').update(is, 'utf8').digest('hex');
      if (factoid && this.tableDescription.count({
        factoid_id: factoid.factoidId,
        hash: hash
      })) {
        return null;
      }

      // Handle or (||)
      if (is.match(/\|\|/)) {
        factoid.isOr = 1;
        factoid.save();
        
        const facts = is.split(/ \|\| /);
        for (const fact of facts) {
          const factHash = crypto.createHash('sha1').update(fact, 'utf8').digest('hex');
          this.tableDescription.create({
            factoid_id: factoid.factoidId,
            description: fact,
            hash: factHash,
            user: from,
            updated: Math.floor(Date.now() / 1000)
          });
        }
      } else {
        this.tableDescription.create({
          factoid_id: factoid.factoidId,
          description: is,
          hash: hash,
          user: from,
          updated: Math.floor(Date.now() / 1000)
        });
      }
    }

    // Retrieve factoid description
    const facts = this.tableDescription.search({
      factoid_id: factoid.factoidId
    });

    // If facts are given, return hashref of factoid data and facts
    if (facts.length > 0) {
      if (facts.length === 1) {
        return {
          user: facts[0].user,
          factoid: factoid,
          facts: [facts[0].description]
        };
      } else {
        return {
          factoid: factoid,
          facts: facts.map(f => f.description)
        };
      }
    }

    return null;
  }

  forget(subject) {
    subject = subject.toLowerCase();

    const factoid = this.searchOne({ subject });
    if (!factoid) {
      return false;
    }

    const facts = this.tableDescription.search({
      factoid_id: factoid.factoidId
    });
    
    for (const fact of facts) {
      fact.delete();
    }
    
    factoid.delete();

    return true;
  }

  ignore(subject, store = false) {
    subject = subject.toLowerCase();

    let ignore = this.tableIgnore.searchOne({ subject });
    
    if (store && !ignore) {
      this.tableIgnore.create({ subject });
      ignore = this.tableIgnore.searchOne({ subject });
    }

    return ignore;
  }
}

export default Factoid;
