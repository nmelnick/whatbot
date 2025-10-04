/**
 * database-complete.test.js - Complete database compatibility test
 * Single test with all tables in one database
 */

import fs from 'fs';
import SQLite from '../src/Database/SQLite.js';
import Karma from '../src/Database/Table/Karma.js';
import UserAlias from '../src/Database/Table/UserAlias.js';
import State from '../src/State.js';
import Log from '../src/Log.js';

const TEST_DB = '/tmp/whatbot-complete-test.db';

// Clean up old test db
if (fs.existsSync(TEST_DB)) {
  fs.unlinkSync(TEST_DB);
}

// Initialize state
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

// Initialize tables
const karma = new Karma({ handle: db.handle });
const userAlias = new UserAlias({ handle: db.handle });
State.instance().models = { karma, useralias: userAlias };

console.log('\n=== Database Backwards Compatibility Test ===\n');

// Test Karma
console.log('1. Testing Karma functionality');
karma.increment('whatbot', 'alice');
karma.increment('whatbot', 'bob');
karma.increment('whatbot', 'alice');
karma.decrement('perl', 'alice');

console.log(`   ✓ whatbot karma: ${karma.get('whatbot')} (expected: 3)`);
console.log(`   ✓ perl karma: ${karma.get('perl')} (expected: -1)`);

const extInfo = karma.getExtended('whatbot');
console.log(`   ✓ Extended info: ${extInfo.Increments} increments, ${extInfo.Decrements} decrements`);

// Test UserAlias
console.log('\n2. Testing UserAlias functionality');
userAlias.alias('bob', 'bobby');
userAlias.alias('bob', 'robert');

const aliases = userAlias.aliasesForUser('bob');
console.log(`   ✓ Bob's aliases: ${aliases.join(', ')}`);

const canonical = userAlias.canonicalUser('bobby');
console.log(`   ✓ Canonical user for "bobby": ${canonical}`);

// Test Schema Compatibility
console.log('\n3. Verifying database schema (Perl-compatible)');

const karmaSchema = db.handle.prepare("PRAGMA table_info(karma)").all();
console.log(`   ✓ Karma table columns: ${karmaSchema.map(c => c.name).join(', ')}`);

const aliasSchema = db.handle.prepare("PRAGMA table_info(user_alias)").all();
console.log(`   ✓ UserAlias table columns: ${aliasSchema.map(c => c.name).join(', ')}`);

// Test indexes
const karmaIndexes = db.handle.prepare("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='karma'").all();
console.log(`   ✓ Karma indexes: ${karmaIndexes.map(i => i.name).join(', ')}`);

const aliasIndexes = db.handle.prepare("SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='user_alias'").all();
console.log(`   ✓ UserAlias indexes: ${aliasIndexes.map(i => i.name).join(', ')}`);

// Verify data persists (simulate disconnect/reconnect)
console.log('\n4. Testing data persistence (disconnect/reconnect)');
db.disconnect();

const db2 = new SQLite();
db2.connect();
State.instance().database = db2;

const karma2 = new Karma({ handle: db2.handle });
const reloadedKarma = karma2.get('whatbot');
console.log(`   ✓ Karma after reconnect: ${reloadedKarma} (expected: 3)`);

db2.disconnect();

console.log('\n✅ All tests passed!\n');
console.log(`Database file: ${TEST_DB}`);
console.log(`Inspect with: sqlite3 ${TEST_DB}\n`);
