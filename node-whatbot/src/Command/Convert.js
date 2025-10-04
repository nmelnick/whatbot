import Command from './Command.js';
import convert from 'convert-units';

class Convert extends Command {
  constructor(config) {
    super(config);
    this._buildUnitLookup();
  }

  _buildUnitLookup() {
    const allUnits = convert().possibilities();
    this.unitLookup = {};
    for (const unit of allUnits) {
      this.unitLookup[unit.toLowerCase()] = unit;
    }
  }

  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    this.commandRegEx('([\\-\\d\\.,]+)\\s?(.*?)\\s+to\\s+(.*)', 'doConvert');
  }

  async doConvert(message, captures) {
    if (!captures || captures.length < 3) return null;

    let [value, fromInput, toInput] = captures;
    value = parseFloat(value.replace(/,/g, ''));
    
    if (isNaN(value)) return null;

    const from = this.unitLookup[fromInput.trim().toLowerCase()];
    const to = this.unitLookup[toInput.trim().toLowerCase()];

    if (!from || !to) {
      return `I cannot convert from ${fromInput} to ${toInput}.`;
    }

    try {
      const result = convert(value).from(from).to(to);
      const formatted = this._formatNumber(result);
      return `${message.from}, should be ${formatted} ${toInput}.`;
    } catch (err) {
      return `I cannot convert from ${fromInput} to ${toInput}.`;
    }
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
      'Supports: temperature (F/C/K), length (ft/m/mi/km/in/cm), weight (lb/kg/oz/g), and more',
      'Example: convert 100 fahrenheit to celsius'
    ];
  }
}

export default Convert;
