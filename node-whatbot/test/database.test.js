/**
 * database.test.js - Database compatibility tests
 * Tests that node-whatbot can read and write to Perl whatbot databases
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import SQLite from '../src/Database/SQLite.js';
import Karma from '../src/Database/Table/Karma.js';
import UserAlias from '../src/Database/Table/UserAlias.js';
import State from '../src/State.js';
import Config from '../src/Config.js';
import Log from '../src/Log.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const TEST_DB = '/tmp/whatbot-test.db';

// Helper to initialize state for testing
function initTestState() {
  // Clean up old test db
  if (fs.existsSync(TEST_DB)) {
    fs.unlinkSync(TEST_DB);
  }

  const config = {
    database: { database: TEST_DB, handler: 'SQLite' },
    log: { directory: '/tmp/whatbot' },
    io: []
  };

  const log = new Log({ log_directory: '/tmp/whatbot' });
  
  State.reset();
  State.initialize({
    parent: null,
    config: { config_hash: config, database: config.database, logDirectory: config.log.directory },
    log: log
  });

  const db = new SQLite();
  db.connect();
  State.instance().database = db;

  return { db, log };
}

// Test Karma table
console.log('\n=== Testing Karma Table ===\n');

const { db: karmaDb } = initTestState();

const karma = new Karma({ handle: karmaDb.handle });
State.instance().models = { karma };

// Test increment
console.log('Test: Increment karma for "nodejs"');
karma.increment('nodejs', 'alice');
karma.increment('nodejs', 'bob');
karma.increment('nodejs', 'alice');

const nodejsKarma = karma.get('nodejs');
console.log(`✓ nodejs karma: ${nodejsKarma} (expected: 3)`);
console.assert(nodejsKarma === 3, 'Karma should be 3');

// Test decrement
console.log('\nTest: Decrement karma for "perl"');
karma.decrement('perl', 'alice');
karma.decrement('perl', 'charlie');

const perlKarma = karma.get('perl');
console.log(`✓ perl karma: ${perlKarma} (expected: -2)`);
console.assert(perlKarma === -2, 'Karma should be -2');

// Test get_extended
console.log('\nTest: Get extended karma info');
const extendedInfo = karma.getExtended('nodejs');
console.log(`✓ Extended info:`, extendedInfo);
console.assert(extendedInfo.Increments === 3, 'Should have 3 increments');
console.assert(extendedInfo.Decrements === 0, 'Should have 0 decrements');
console.assert(extendedInfo.Last[0] === 'alice', 'Last user should be alice');

// Test top_n
console.log('\nTest: Top karma by user "alice"');
const topKarma = karma.topN('alice', 10);
console.log(`✓ Top karma:`, topKarma);

karmaDb.disconnect();

// Test UserAlias table
console.log('\n\n=== Testing UserAlias Table ===\n');

const { db: aliasDb } = initTestState();

const userAlias = new UserAlias({ handle: aliasDb.handle });
State.instance().models = { useralias: userAlias };

// Test alias creation
console.log('Test: Create aliases for "bob"');
userAlias.alias('bob', 'bobby');
userAlias.alias('bob', 'robert');

const bobAliases = userAlias.aliasesForUser('bob');
console.log(`✓ Bob's aliases:`, bobAliases);
console.assert(bobAliases.length === 2, 'Should have 2 aliases');

// Test user_for_alias
console.log('\nTest: Get user for alias "bobby"');
const userForBobby = userAlias.userForAlias('bobby');
console.log(`✓ User for "bobby": ${userForBobby} (expected: bob)`);
console.assert(userForBobby === 'bob', 'Should return bob');

// Test canonical_user
console.log('\nTest: Get canonical user');
const canonical1 = userAlias.canonicalUser('bobby');
const canonical2 = userAlias.canonicalUser('alice');
console.log(`✓ Canonical for "bobby": ${canonical1} (expected: bob)`);
console.log(`✓ Canonical for "alice": ${canonical2} (expected: alice)`);
console.assert(canonical1 === 'bob', 'Should return bob');
console.assert(canonical2 === 'alice', 'Should return alice (unchanged)');

// Test remove
console.log('\nTest: Remove alias');
userAlias.remove('bob', 'bobby');
const afterRemove = userAlias.aliasesForUser('bob');
console.log(`✓ Bob's aliases after removal:`, afterRemove);
console.assert(afterRemove.length === 1, 'Should have 1 alias left');

// Test database schema compatibility (before disconnecting)
console.log('\n\n=== Testing Schema Compatibility ===\n');

console.log('Test: Verify karma table schema');
const karmaSchema = aliasDb.handle.prepare("PRAGMA table_info(karma)").all();
console.log('✓ Karma columns:', karmaSchema.map(c => c.name).join(', '));

const expectedKarmaColumns = ['karma_id', 'subject', 'user', 'created', 'amount'];
for (const col of expectedKarmaColumns) {
  console.assert(
    karmaSchema.find(c => c.name === col),
    `Karma table should have ${col} column`
  );
}

console.log('\nTest: Verify user_alias table schema');
const aliasSchema = aliasDb.handle.prepare("PRAGMA table_info(user_alias)").all();
console.log('✓ UserAlias columns:', aliasSchema.map(c => c.name).join(', '));

const expectedAliasColumns = ['user_alias_id', 'user', 'alias'];
for (const col of expectedAliasColumns) {
  console.assert(
    aliasSchema.find(c => c.name === col),
    `UserAlias table should have ${col} column`
  );
}

aliasDb.disconnect();

console.log('\n\n✅ All database tests passed!\n');
console.log('Database file created at:', TEST_DB);
console.log('You can inspect it with: sqlite3', TEST_DB);
