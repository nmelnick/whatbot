/**
 * MySQL Database Handler and Web IO Test
 * Quick validation for MySQL and Web modules
 */

console.log('MySQL and Web Module Test');
console.log('==========================\n');

try {
  const MySQL = (await import('../src/Database/MySQL.js')).default;
  const Web = (await import('../src/IO/Web.js')).default;
  
  console.log('✓ MySQL and Web modules load successfully');
  
  if (typeof MySQL === 'function' && typeof Web === 'function') {
    console.log('✓ MySQL and Web classes are constructors');
  }
  
  const mysqlInstance = new MySQL();
  const webInstance = new Web({ my_config: { port: 3000 } });
  
  if (mysqlInstance && webInstance) {
    console.log('✓ MySQL and Web instances created successfully');
  }
  
  // Verify MySQL methods
  if (typeof mysqlInstance.connect === 'function' &&
      typeof mysqlInstance.disconnect === 'function' &&
      typeof mysqlInstance.getTables === 'function' &&
      typeof mysqlInstance.lastInsertId === 'function' &&
      typeof mysqlInstance.integer === 'function' &&
      typeof mysqlInstance.serial === 'function' &&
      typeof mysqlInstance.random === 'function') {
    console.log('✓ All MySQL methods are defined');
  }
  
  // Verify Web methods
  if (typeof webInstance.connect === 'function' &&
      typeof webInstance.disconnect === 'function' &&
      typeof webInstance.addDispatch === 'function' &&
      typeof webInstance.logResponse === 'function') {
    console.log('✓ All Web methods are defined');
  }
  
  console.log('\n✅ MySQL and Web validation complete!');
  console.log('\nNote: Actual usage requires:');
  console.log('  MySQL: npm install mysql2 + running MySQL server');
  console.log('  Web: npm install express');
  
} catch (error) {
  console.error('❌ Test failed:', error);
  process.exit(1);
}
