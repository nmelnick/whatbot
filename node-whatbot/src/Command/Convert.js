import Command from './Command.js';

class Convert extends Command {
  constructor(config) {
    super(config);
    this.conversions = this._buildConversions();
  }

  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.commandRegEx(/([\-\d\.,]+)\s?(.*?)\s+to\s+(.*)/, 'doConvert');
  }

  async doConvert(message, captures) {
    if (!captures || captures.length < 3) return null;

    let [value, from, to] = captures;
    value = parseFloat(value.replace(/,/g, ''));
    
    if (isNaN(value)) return null;

    from = from.trim().toLowerCase();
    to = to.trim().toLowerCase();

    const result = this._convert(value, from, to);
    
    if (result === null) {
      return `I cannot convert from ${from} to ${to}.`;
    }

    const formatted = this._formatNumber(result);
    return `${message.from}, should be ${formatted} ${to}.`;
  }

  _convert(value, from, to) {
    from = this._normalizeUnit(from);
    to = this._normalizeUnit(to);

    if (!this.conversions[from] || !this.conversions[from][to]) {
      return null;
    }

    return this.conversions[from][to](value);
  }

  _normalizeUnit(unit) {
    unit = unit.toLowerCase();
    
    const aliases = {
      'f': 'fahrenheit', 'fahrenheit': 'fahrenheit',
      'c': 'celsius', 'celsius': 'celsius', 'centigrade': 'celsius',
      'k': 'kelvin', 'kelvin': 'kelvin',
      'ft': 'feet', 'foot': 'feet', 'feet': 'feet',
      'm': 'meters', 'meter': 'meters', 'meters': 'meters', 'metre': 'meters', 'metres': 'meters',
      'mi': 'miles', 'mile': 'miles', 'miles': 'miles',
      'km': 'kilometers', 'kilometer': 'kilometers', 'kilometers': 'kilometers', 'kilometre': 'kilometers', 'kilometres': 'kilometers',
      'in': 'inches', 'inch': 'inches', 'inches': 'inches',
      'cm': 'centimeters', 'centimeter': 'centimeters', 'centimeters': 'centimeters', 'centimetre': 'centimeters', 'centimetres': 'centimeters',
      'lb': 'pounds', 'lbs': 'pounds', 'pound': 'pounds', 'pounds': 'pounds',
      'kg': 'kilograms', 'kilogram': 'kilograms', 'kilograms': 'kilograms', 'kilo': 'kilograms', 'kilos': 'kilograms',
      'oz': 'ounces', 'ounce': 'ounces', 'ounces': 'ounces',
      'g': 'grams', 'gram': 'grams', 'grams': 'grams'
    };

    return aliases[unit] || unit;
  }

  _buildConversions() {
    return {
      // Temperature
      'fahrenheit': {
        'celsius': (f) => (f - 32) * 5 / 9,
        'kelvin': (f) => (f - 32) * 5 / 9 + 273.15,
        'fahrenheit': (f) => f
      },
      'celsius': {
        'fahrenheit': (c) => c * 9 / 5 + 32,
        'kelvin': (c) => c + 273.15,
        'celsius': (c) => c
      },
      'kelvin': {
        'celsius': (k) => k - 273.15,
        'fahrenheit': (k) => (k - 273.15) * 9 / 5 + 32,
        'kelvin': (k) => k
      },
      
      // Length
      'feet': {
        'meters': (ft) => ft * 0.3048,
        'miles': (ft) => ft / 5280,
        'kilometers': (ft) => ft * 0.0003048,
        'inches': (ft) => ft * 12,
        'centimeters': (ft) => ft * 30.48,
        'feet': (ft) => ft
      },
      'meters': {
        'feet': (m) => m / 0.3048,
        'miles': (m) => m / 1609.344,
        'kilometers': (m) => m / 1000,
        'inches': (m) => m / 0.0254,
        'centimeters': (m) => m * 100,
        'meters': (m) => m
      },
      'miles': {
        'feet': (mi) => mi * 5280,
        'meters': (mi) => mi * 1609.344,
        'kilometers': (mi) => mi * 1.609344,
        'inches': (mi) => mi * 63360,
        'centimeters': (mi) => mi * 160934.4,
        'miles': (mi) => mi
      },
      'kilometers': {
        'feet': (km) => km * 3280.84,
        'meters': (km) => km * 1000,
        'miles': (km) => km / 1.609344,
        'inches': (km) => km * 39370.1,
        'centimeters': (km) => km * 100000,
        'kilometers': (km) => km
      },
      'inches': {
        'feet': (i) => i / 12,
        'meters': (i) => i * 0.0254,
        'miles': (i) => i / 63360,
        'kilometers': (i) => i / 39370.1,
        'centimeters': (i) => i * 2.54,
        'inches': (i) => i
      },
      'centimeters': {
        'feet': (cm) => cm / 30.48,
        'meters': (cm) => cm / 100,
        'miles': (cm) => cm / 160934.4,
        'kilometers': (cm) => cm / 100000,
        'inches': (cm) => cm / 2.54,
        'centimeters': (cm) => cm
      },
      
      // Weight
      'pounds': {
        'kilograms': (lb) => lb * 0.453592,
        'ounces': (lb) => lb * 16,
        'grams': (lb) => lb * 453.592,
        'pounds': (lb) => lb
      },
      'kilograms': {
        'pounds': (kg) => kg / 0.453592,
        'ounces': (kg) => kg * 35.274,
        'grams': (kg) => kg * 1000,
        'kilograms': (kg) => kg
      },
      'ounces': {
        'pounds': (oz) => oz / 16,
        'kilograms': (oz) => oz / 35.274,
        'grams': (oz) => oz * 28.3495,
        'ounces': (oz) => oz
      },
      'grams': {
        'pounds': (g) => g / 453.592,
        'kilograms': (g) => g / 1000,
        'ounces': (g) => g / 28.3495,
        'grams': (g) => g
      }
    };
  }

  _formatNumber(num) {
    if (Number.isInteger(num)) {
      return num.toString();
    }
    return num.toFixed(2).replace(/\.?0+$/, '');
  }

  help() {
    return [
      'Convert performs unit conversions.',
      'Usage: convert <value> <from-unit> to <to-unit>',
      'Supports: temperature (F/C/K), length (ft/m/mi/km/in/cm), weight (lb/kg/oz/g)',
      'Example: convert 100 fahrenheit to celsius'
    ];
  }
}

export default Convert;
