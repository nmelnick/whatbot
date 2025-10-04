/**
 * PostgreSQL Database Handler Test
 * Quick validation for PostgreSQL module
 */

console.log('PostgreSQL Database Handler Test');
console.log('=================================\n');

try {
  const PostgreSQL = (await import('../src/Database/PostgreSQL.js')).default;
  
  console.log('✓ PostgreSQL module loads successfully');
  
  if (typeof PostgreSQL === 'function') {
    console.log('✓ PostgreSQL class is a constructor');
  }
  
  const instance = new PostgreSQL();
  if (instance) {
    console.log('✓ PostgreSQL instance created successfully');
  }
  
  // Verify key methods exist
  if (typeof instance.connect === 'function' &&
      typeof instance.disconnect === 'function' &&
      typeof instance.getTables === 'function' &&
      typeof instance.lastInsertId === 'function' &&
      typeof instance.serial === 'function' &&
      typeof instance.query === 'function') {
    console.log('✓ All required methods are defined');
  }
  
  console.log('\n✅ PostgreSQL validation complete!');
  console.log('\nNote: Actual database connection requires:');
  console.log('  - npm install pg');
  console.log('  - Running PostgreSQL server');
  console.log('  - Proper configuration');
  
} catch (error) {
  console.error('❌ Test failed:', error);
  process.exit(1);
}
