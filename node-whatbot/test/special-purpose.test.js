/**
 * Special Purpose Commands Test
 * Quick validation for Dashboard, Calendar, API, Awareness, FactoidListener
 */

console.log('Special Purpose Commands Test');
console.log('==============================\n');

try {
  const Dashboard = (await import('../src/Command/Dashboard.js')).default;
  const Calendar = (await import('../src/Command/Calendar.js')).default;
  const API = (await import('../src/Command/API.js')).default;
  const Awareness = (await import('../src/Command/Awareness.js')).default;
  const FactoidListener = (await import('../src/Command/FactoidListener.js')).default;
  
  console.log('✓ All Special Purpose modules load successfully');
  
  if (Dashboard && Calendar && API && Awareness && FactoidListener) {
    console.log('✓ All Special Purpose classes are defined');
  }
  
  if (typeof Dashboard === 'function' && 
      typeof Calendar === 'function' && 
      typeof API === 'function' &&
      typeof Awareness === 'function' &&
      typeof FactoidListener === 'function') {
    console.log('✓ All Special Purpose command classes are constructors');
  }
  
  console.log('\n✅ Special Purpose validation complete!');
  
} catch (error) {
  console.error('❌ Test failed:', error);
  process.exit(1);
}
