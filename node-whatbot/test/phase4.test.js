/**
 * Phase 4 Advanced Features Test
 * Quick validation for Bother, At, Paste commands
 */

console.log('Phase 4 Advanced Features Test');
console.log('==============================\n');

// Test imports
try {
  const Bother = (await import('../src/Command/Bother.js')).default;
  const At = (await import('../src/Command/At.js')).default;
  const Paste = (await import('../src/Command/Paste.js')).default;
  const BotherTable = (await import('../src/Database/Table/Bother.js')).default;
  const PasteTable = (await import('../src/Database/Table/Paste.js')).default;
  
  console.log('✓ All Phase 4 modules load successfully');
  
  // Verify classes exist
  if (Bother && At && Paste && BotherTable && PasteTable) {
    console.log('✓ All Phase 4 classes are defined');
  }
  
  // Verify they are constructors
  if (typeof Bother === 'function' && 
      typeof At === 'function' && 
      typeof Paste === 'function' &&
      typeof BotherTable === 'function' &&
      typeof PasteTable === 'function') {
    console.log('✓ All Phase 4 classes are constructors');
  }
  
  console.log('\n✅ Phase 4 validation complete!');
  
} catch (error) {
  console.error('❌ Test failed:', error);
  process.exit(1);
}
