class Current {
  constructor({ displayLocation, conditions, temperatureF, feelsLikeF }) {
    this.displayLocation = displayLocation;
    this.conditions = conditions;
    this.temperatureF = temperatureF;
    this.feelsLikeF = feelsLikeF;
    this.alerts = [];
  }

  addAlert(alert) {
    this.alerts.push(alert);
  }

  hasAlerts() {
    return this.alerts.length > 0;
  }

  uniqueAlerts() {
    return [...new Set(this.alerts)];
  }

  toCelsius(fahrenheit) {
    return ((fahrenheit - 32) * 5) / 9;
  }

  tempString(fahrenheit) {
    return `${Math.round(fahrenheit)} F (${this.toCelsius(fahrenheit).toFixed(2)} C)`;
  }

  toString() {
    const feelsLikePart = this.feelsLikeF ? `, feels like ${this.tempString(this.feelsLikeF)}` : '';
    const alertsPart = this.hasAlerts() ? ` Alerts: ${this.uniqueAlerts().join(', ')}` : '';
    
    return `Weather for ${this.displayLocation}: Currently ${this.conditions} and ${this.tempString(this.temperatureF)}${feelsLikePart}.${alertsPart}`;
  }
}

export default Current;
