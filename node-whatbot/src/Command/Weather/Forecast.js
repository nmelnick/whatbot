class Forecast {
  constructor({ weekday, conditions, highTemperatureF, lowTemperatureF }) {
    this.weekday = weekday;
    this.conditions = conditions || '';
    this.highTemperatureF = highTemperatureF;
    this.lowTemperatureF = lowTemperatureF;
  }

  toCelsius(fahrenheit) {
    return ((fahrenheit - 32) * 5) / 9;
  }

  tempString(fahrenheit) {
    return `${Math.round(fahrenheit)} F (${this.toCelsius(fahrenheit).toFixed(2)} C)`;
  }

  toString() {
    return `${this.weekday}: ${this.conditions} [H: ${this.tempString(this.highTemperatureF)}, L: ${this.tempString(this.lowTemperatureF)}]`;
  }
}

export default Forecast;
