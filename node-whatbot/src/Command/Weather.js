import Command from './Command.js';
import OpenWeatherMap from './Weather/OpenWeatherMap.js';
import OpenMeteo from './Weather/OpenMeteo.js';

class Weather extends Command {
  register() {
    this.priority = 'Extension';
    this.requireDirect = false;

    const config = this.my_config;
    if (!config || !config.source) {
      return;
    }

    if (config.source === 'openweathermap') {
      this.source = new OpenWeatherMap(config);
    } else if (config.source === 'openmeteo') {
      this.source = new OpenMeteo(config);
    }

    // Register patterns
    this.globalRegEx(/^weather\s+forecast\s+(.+)$/i, 'forecast');
    this.globalRegEx(/^weather\s+(?!forecast\s)(.+)$/i, 'weather');
  }

  async forecast(message, captures) {
    if (!this.source) {
      return null;
    }

    const location = captures[0];
    try {
      const forecasts = await this.source.getForecast(location);
      if (forecasts && Array.isArray(forecasts)) {
        return forecasts.map(f => f.toString());
      }
      return 'Iunno.';
    } catch (error) {
      return error.message || 'Iunno.';
    }
  }

  async weather(message, captures) {
    if (!this.source) {
      return null;
    }

    const location = captures[0];
    try {
      const current = await this.source.getCurrent(location);
      if (current) {
        return current.toString();
      }
      return 'Iunno.';
    } catch (error) {
      return error.message || 'Iunno.';
    }
  }

  help() {
    return [
      'Weather grabs the temperature and alerts for a zip code or "City, Country".',
      'Usage: weather 10101',
      'Usage: weather Toronto, Canada',
      'Usage: forecast 10101'
    ];
  }
}

Weather.prototype.forecast.isGlobalRegEx = true;
Weather.prototype.forecast.pattern = /^forecast (.+)/i;

Weather.prototype.weather.isGlobalRegEx = true;
Weather.prototype.weather.pattern = /^weather (.+)/i;

export default Weather;
