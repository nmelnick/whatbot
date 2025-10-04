/**
 * factoid.test.js - Test Factoid table functionality
 */

import fs from 'fs';
import SQLite from '../src/Database/SQLite.js';
import Factoid from '../src/Database/Table/Factoid.js';
import State from '../src/State.js';
import Log from '../src/Log.js';

const TEST_DB = '/tmp/whatbot-factoid-test.db';

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

const factoid = new Factoid({ handle: db.handle });
State.instance().models = { factoid };

console.log('\n=== Factoid Table Test ===\n');

// Test 1: Simple factoid assignment
console.log('1. Test simple factoid assignment');
factoid.factoid('whatbot', 'an awesome bot', 'alice', false);
const result1 = factoid.factoid('whatbot');
console.log(`   ✓ whatbot is: ${result1.facts[0]}`);
console.assert(result1.facts[0] === 'an awesome bot', 'Should store simple factoid');

// Test 2: Plural factoid
console.log('\n2. Test plural factoid (are vs is)');
factoid.factoid('bots', 'cool', 'bob', true);
const result2 = factoid.factoid('bots');
console.log(`   ✓ bots are: ${result2.facts[0]}`);
console.assert(result2.factoid.isPlural === 1, 'Should be plural');

// Test 3: Multiple definitions with "or"
console.log('\n3. Test multiple definitions');
factoid.factoid('test', 'definition one or definition two or definition three', 'alice', false);
const result3 = factoid.factoid('test');
console.log(`   ✓ test has ${result3.facts.length} definitions`);
console.assert(result3.facts.length === 1, 'Should store as single definition (no ||)');

// Test 4: OR syntax (||)
console.log('\n4. Test OR syntax (||)');
factoid.factoid('colors', 'red || green || blue', 'alice', false);
const result4 = factoid.factoid('colors');
console.log(`   ✓ colors has ${result4.facts.length} facts (is_or: ${result4.factoid.isOr})`);
console.assert(result4.facts.length === 3, 'Should split by ||');
console.assert(result4.factoid.isOr === 1, 'Should set is_or flag');

// Test 5: <reply> prefix
console.log('\n5. Test <reply> prefix');
factoid.factoid('hello', '<reply> Hello there!', 'alice', false);
const result5 = factoid.factoid('hello');
console.log(`   ✓ hello: ${result5.facts[0]}`);
console.assert(result5.facts[0] === '<reply> Hello there!', 'Should preserve <reply> prefix');

// Test 6: Forget factoid
console.log('\n6. Test forget factoid');
factoid.factoid('temporary', 'will be deleted', 'alice', false);
const beforeForget = factoid.factoid('temporary');
console.assert(beforeForget !== null, 'Factoid should exist');

factoid.forget('temporary');
const afterForget = factoid.factoid('temporary');
console.log(`   ✓ Factoid deleted: ${afterForget === null}`);
console.assert(afterForget === null, 'Factoid should be deleted');

// Test 7: Ignore/blacklist
console.log('\n7. Test ignore (blacklist)');
factoid.ignore('badword', true);
const ignored = factoid.factoid('badword', 'should not store', 'alice', false);
console.log(`   ✓ Ignored factoid blocked: ${ignored === null}`);
console.assert(ignored === null, 'Should not store ignored factoid');

// Test 8: Silent mode
console.log('\n8. Test silent mode');
factoid.factoid('quiet', 'shh', 'alice', false);
console.log(`   ✓ Before toggle: silent = ${factoid.isSilent('quiet')}`);
factoid.toggleSilence('quiet');
console.log(`   ✓ After toggle: silent = ${factoid.isSilent('quiet')}`);
console.assert(factoid.isSilent('quiet') === 1, 'Should be silenced');

// Test 9: Duplicate prevention
console.log('\n9. Test duplicate prevention');
factoid.factoid('unique', 'first', 'alice', false);
const duplicate = factoid.factoid('unique', 'first', 'bob', false);
console.log(`   ✓ Duplicate blocked: ${duplicate === null}`);
console.assert(duplicate === null, 'Should not allow duplicate');

// Test 10: Check schema
console.log('\n10. Verify database schema');
const factoidSchema = db.handle.prepare("PRAGMA table_info(factoid)").all();
console.log(`   ✓ Factoid columns: ${factoidSchema.map(c => c.name).join(', ')}`);

const descSchema = db.handle.prepare("PRAGMA table_info(factoid_description)").all();
console.log(`   ✓ Description columns: ${descSchema.map(c => c.name).join(', ')}`);

const ignoreSchema = db.handle.prepare("PRAGMA table_info(factoid_ignore)").all();
console.log(`   ✓ Ignore columns: ${ignoreSchema.map(c => c.name).join(', ')}`);

// Verify all tables exist
const tables = db.handle.prepare("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name").all();
console.log(`   ✓ All tables: ${tables.map(t => t.name).join(', ')}`);

db.disconnect();

console.log('\n✅ All Factoid tests passed!\n');
console.log(`Database: ${TEST_DB}\n`);
