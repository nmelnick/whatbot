/**
 * Phase 2 IO Modules Test
 * Quick validation for IRC, Slack, Timer modules
 */

console.log('Phase 2 IO Modules Test');
console.log('=======================\n');

// Test imports
try {
  const IRC = (await import('../src/IO/IRC.js')).default;
  const Slack = (await import('../src/IO/Slack.js')).default;
  const Timer = (await import('../src/IO/Timer.js')).default;
  
  console.log('✓ All Phase 2 modules load successfully');
  
  // Verify classes exist
  if (IRC && Slack && Timer) {
    console.log('✓ All Phase 2 IO classes are defined');
  }
  
  // Verify they are constructors
  if (typeof IRC === 'function' && 
      typeof Slack === 'function' && 
      typeof Timer === 'function') {
    console.log('✓ All Phase 2 IO classes are constructors');
  }
  
  console.log('\n✅ Phase 2 validation complete!');
  
} catch (error) {
  console.error('❌ Test failed:', error);
  process.exit(1);
}
