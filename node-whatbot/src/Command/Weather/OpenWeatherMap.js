import https from 'https';
import Current from './Current.js';
import Forecast from './Forecast.js';

class OpenWeatherMap {
  constructor(config) {
    this.apiKey = config.api_key;
    if (!this.apiKey) {
      throw new Error('OpenWeatherMap requires api_key in config');
    }
  }

  async getCurrent(location) {
    const query = this._parseLocation(location);
    const url = `https://api.openweathermap.org/data/2.5/weather?units=imperial&APPID=${this.apiKey}&${query}`;
    
    const data = await this._fetchJson(url);
    
    if (data.name) {
      return new Current({
        displayLocation: data.name,
        conditions: data.weather[0].description,
        temperatureF: data.main.temp,
        feelsLikeF: data.main.feels_like
      });
    }
    
    return null;
  }

  async getForecast(location) {
    const query = this._parseLocation(location);
    const url = `https://api.openweathermap.org/data/2.5/forecast?units=imperial&APPID=${this.apiKey}&${query}`;
    
    const data = await this._fetchJson(url);
    
    if (!data || !data.city) {
      return null;
    }

    const seenDates = {};
    
    for (const forecast of data.list) {
      const date = forecast.dt_txt.substring(0, 10);
      
      if (!seenDates[date]) {
        seenDates[date] = new Forecast({
          weekday: date,
          highTemperatureF: forecast.main.temp_max,
          lowTemperatureF: forecast.main.temp_min,
          conditions: forecast.weather[0].description
        });
      } else {
        if (!seenDates[date].highTemperatureF || seenDates[date].highTemperatureF < forecast.main.temp_max) {
          seenDates[date].highTemperatureF = forecast.main.temp_max;
        }
        if (!seenDates[date].lowTemperatureF || seenDates[date].lowTemperatureF > forecast.main.temp_min) {
          seenDates[date].lowTemperatureF = forecast.main.temp_min;
        }
        
        const condition = forecast.weather[0].description;
        if (!seenDates[date].conditions.includes(condition)) {
          if (seenDates[date].conditions) {
            seenDates[date].conditions += ', ';
          }
          seenDates[date].conditions += condition;
        }
      }
    }

    const sortedDates = Object.keys(seenDates).sort();
    return sortedDates.slice(0, 3).map(date => seenDates[date]);
  }

  _parseLocation(location) {
    if (/^\d{5}$/.test(location)) {
      return `zip=${location}`;
    } else if (/^([^,]+),\s*(\w{2})/.test(location)) {
      const match = location.match(/^([^,]+),\s*(\w{2})/);
      const city = match[1].replace(/ /g, '%20');
      const country = match[2];
      return `q=${city},${country}`;
    } else {
      throw new Error(`Unwilling to figure out what you meant by "${location}"`);
    }
  }

  _fetchJson(url) {
    return new Promise((resolve, reject) => {
      https.get(url, (res) => {
        let data = '';
        
        res.on('data', (chunk) => {
          data += chunk;
        });
        
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(e);
          }
        });
      }).on('error', (err) => {
        reject(err);
      });
    });
  }
}

export default OpenWeatherMap;
