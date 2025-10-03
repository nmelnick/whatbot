/**
 * Phase 3 Utility Commands Test
 * Quick validation for Admin, Convert, KarmaHistory
 */

console.log('Phase 3 Utility Commands Test');
console.log('==============================\n');

// Test imports
try {
  const Admin = (await import('../src/Command/Admin.js')).default;
  const Convert = (await import('../src/Command/Convert.js')).default;
  const KarmaHistory = (await import('../src/Command/KarmaHistory.js')).default;
  
  console.log('✓ All Phase 3 modules load successfully');
  
  // Verify classes exist
  if (Admin && Convert && KarmaHistory) {
    console.log('✓ All Phase 3 classes are defined');
  }
  
  // Verify they are constructors
  if (typeof Admin === 'function' && 
      typeof Convert === 'function' && 
      typeof KarmaHistory === 'function') {
    console.log('✓ All Phase 3 command classes are constructors');
  }
  
  console.log('\n✅ Phase 3 validation complete!');
  
} catch (error) {
  console.error('❌ Test failed:', error);
  process.exit(1);
}
