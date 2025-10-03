import https from 'https';
import Current from './Current.js';
import Forecast from './Forecast.js';

class OpenMeteo {
  constructor(config) {
    this.weatherCodesEn = [
      // No precipitation
      "Clear", //0
      "Mostly clear",
      "Partly cloudy",
      "Overcast",
      "Smoke",
      "Haze", //5
      "Dust (distant)",
      "Dust or sand",
      "Dust or sand whirls",
      "Dust or sand storm",
      "Mist", //10
      "Mist patches",
      "Thick mist",
      "Distant lightning",
      "Rain within sight",
      "Distant rain", //15
      "Rain nearby (but dry here)",
      "Dry thunderstorm",
      "Squall",
      "Funnel clouds",

      // Recent precipitation
      "Recent drizzle", //20
      "Recent rain", 
      "Recent snow",
      "Recent mixed rain and snow",
      "Recent freezing rain",
      "Recent rainshowers", //25
      "Recent snowshowers",
      "Recent hail",
      "Recent fog",
      "Recent thunderstorm",

      // Dust or sandstorm or blowing snow
      "Dust or sandstorm (decreasing)", //30
      "Dust or sandstorm",
      "Dust or sandstorm (increasing)",
      "Severe dust or sandstorm (decreasing)", 
      "Severe dust or sandstorm",
      "Severe dust or sandstorm (increasing)", //35
      "Low blowing snow",
      "Low, heavy blowing snowdrifts",
      "Blowing snow",
      "Heavy blowing snowdrifts",

      // Fog
      "Nearby or recent fog", //40
      "Patchy fog",
      "Fog (decreasing)",
      "Thick fog (decreasing)",
      "Fog",
      "Thick fog",
      "Fog (increasing)",
      "Thick fog (increasing)",
      "Rime-depositing fog",
      "Thick rime-depositing fog",

      // Precipitation: Drizzle
      "Patches of drizzle (decreasing)", //50
      "Drizzle (decreasing)",
      "Patches of drizzle",
      "Drizzle",
      "Patches of drizzle (increasing)",
      "Drizzle (increasing)",
      "Freezing drizzle",
      "Dense freezing drizzle",
      "Mixed drizzle and rain",
      "Heavy mixed drizzle and rain",

      // Precipitation: Rain
      "Patches of rain (decreasing)", //60
      "Rain (decreasing)",
      "Patches of rain",
      "Rain",
      "Patches of rain (increasing)",
      "Rain (increasing)",
      "Freezing rain",
      "Heavy freezing rain",
      "Mixed rain and snow",
      "Heavy mixed rain and snow",

      // Precipitation: Snow
      "Intermittent snow (decreasing)", //70
      "Snow (decreasing)",
      "Intermittent snow",
      "Snow",
      "Intermittent snow (increasing)",
      "Snow (increasing)",
      "Diamond dust",
      "Snow grains",
      "Isolated star-like snow crystals",
      "Ice pellets",

      // Precipitation: More rain
      "Light rain showers", // 80
      "Rain showers",
      "Violent rain showers",
      "Mixed rain and snow showers",
      "Mixed heavy rain and snow showers",
      "Snow showers", // 85
      "Heavy snow showers",
      "Showers of snow pellets or small hail",
      "Heavy showers of snow pellets or small hail",
      "Hail showers",
      "Heavy hail showers", //90
      "Light rain, recent thunderstorm",
      "Heavy rain, recent thunderstorm", 
      "Light snow or mix, recent thunderstorm",
      "Heavy snow or mix, recent thunderstorm",
      "Recent thunderstorm", //95
      "Thunderstorm with hail",
      "Heavy thunderstorm",
      "Thunderstorm with dust or sandstorm",
      "Heavy thunderstorm with hail" //99
    ];
  }

  async getCurrent(location) {
    const resolved = await this._convertLocation(location);
    const query = this._buildLocationQuery(resolved.coordinates);
    const url = this._getUri(query);
    
    const data = await this._fetchJson(url);
    
    return new Current({
      displayLocation: resolved.display,
      conditions: this.weatherCodesEn[data.current.weather_code],
      temperatureF: data.current.temperature_2m,
      feelsLikeF: data.current.apparent_temperature
    });
  }

  async getForecast(location) {
    const resolved = await this._convertLocation(location);
    const query = this._buildLocationQuery(resolved.coordinates);
    const url = this._getUri(query);
    
    const data = await this._fetchJson(url);
    
    const days = [];
    for (let i = 0; i < 3; i++) {
      const date = data.daily.time[i];
      const weekday = this._getWeekday(date);
      
      days.push(new Forecast({
        weekday: weekday,
        highTemperatureF: data.daily.temperature_2m_max[i],
        lowTemperatureF: data.daily.temperature_2m_min[i],
        conditions: this.weatherCodesEn[data.daily.weather_code[i]]
      }));
    }
    
    return days;
  }

  _getUri(locationQueryParams) {
    return 'https://api.open-meteo.com/v1/forecast?current=temperature_2m,apparent_temperature,weather_code' +
      '&daily=weather_code,temperature_2m_max,temperature_2m_min' +
      '&temperature_unit=fahrenheit&timezone=GMT&' +
      locationQueryParams;
  }

  _buildLocationQuery(coordinates) {
    if (coordinates[0] !== 0 && coordinates[1] !== 0) {
      return `latitude=${coordinates[0]}&longitude=${coordinates[1]}`;
    }
    throw new Error('Could not determine coordinates for that location');
  }

  async _convertLocation(location) {
    const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(location)}&format=json&limit=1`;
    
    const data = await this._fetchJson(url, {
      'User-Agent': 'whatbot/1.0'
    });
    
    if (data && data.length > 0) {
      const result = data[0];
      return {
        coordinates: [parseFloat(result.lat), parseFloat(result.lon)],
        display: result.display_name
      };
    }
    
    return {
      coordinates: [0, 0],
      display: location
    };
  }

  _getWeekday(dateString) {
    const date = new Date(dateString);
    const weekdays = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return weekdays[date.getDay()];
  }

  _fetchJson(url, headers = {}) {
    return new Promise((resolve, reject) => {
      const urlObj = new URL(url);
      const options = {
        hostname: urlObj.hostname,
        path: urlObj.pathname + urlObj.search,
        headers: {
          'User-Agent': 'whatbot/1.0',
          ...headers
        }
      };
      
      https.get(options, (res) => {
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

export default OpenMeteo;
