/**
 * Phase 1 Commands Test
 * Quick validation for Tell, URL, Define, Math commands
 */

console.log('Phase 1 Command Tests');
console.log('====================\n');

// Test imports
try {
  const Tell = (await import('../src/Command/Tell.js')).default;
  const URLCommand = (await import('../src/Command/URL.js')).default;
  const Define = (await import('../src/Command/Define.js')).default;
  const Math = (await import('../src/Command/Math.js')).default;
  const Soup = (await import('../src/Database/Table/Soup.js')).default;
  const URL = (await import('../src/Database/Table/URL.js')).default;
  
  console.log('✓ All Phase 1 modules load successfully');
  
  // Verify classes exist
  if (Tell && URLCommand && Define && Math && Soup && URL) {
    console.log('✓ All Phase 1 classes are defined');
  }
  
  // Verify they are constructors
  if (typeof Tell === 'function' && 
      typeof URLCommand === 'function' && 
      typeof Define === 'function' && 
      typeof Math === 'function') {
    console.log('✓ All Phase 1 command classes are constructors');
  }
  
  if (typeof Soup === 'function' && typeof URL === 'function') {
    console.log('✓ All Phase 1 table classes are constructors');
  }
  
  console.log('\n✅ Phase 1 validation complete!');
  
} catch (error) {
  console.error('❌ Test failed:', error);
  process.exit(1);
}
