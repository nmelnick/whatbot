###########################################################################
# Whatbot/Command/Weather/Openmeteo.pm
###########################################################################
# Retrieve weather from the Openmeteo API - https://open-meteo.com/
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::Command::Weather::Openmeteo
  with Whatbot::Command::Weather::SourceRole
  with Whatbot::Command::Role::Location {
  use DateTime;
  use JSON::XS;
  use Whatbot::Command::Weather::Current;
  use Whatbot::Command::Weather::Forecast;

  has 'weather_codes_en'            => ( is => 'ro', isa => 'ArrayRef[Str]' );

  method _get_uri( Str $location_query_params ) {
    # https://api.open-meteo.com/v1/forecast?
    # latitude=48.4&longitude=-123.4
    # &current=temperature_2m,apparent_temperature,weather_code
    # &daily=weather_code,temperature_2m_max,temperature_2m_min
    # &temperature_unit=fahrenheit&timezone=GMT
    return 
      'https://api.open-meteo.com/v1/forecast?current=temperature_2m,apparent_temperature,weather_code' .
      '&daily=weather_code,temperature_2m_max,temperature_2m_min' .
      '&temperature_unit=fahrenheit&timezone=GMT&' .
      $location_query_params;
  }

  method get_current( Str $location ) {
    use Data::Dumper;
    my $resolved = $self->convert_location($location);
    my $location_query_params = $self->_location($resolved->{'coordinates'});

    my $json = $self->_fetch_and_decode($self->_get_uri($location_query_params));
    my $current_obj = Whatbot::Command::Weather::Current->new({
        'display_location' => $resolved->{'display'},
        'conditions'       => $self->{'weather_codes_en'}->[$json->{'current'}->{'weather_code'}],
        'temperature_f'    => $json->{'current'}->{'temperature_2m'},
        'feels_like_f'     => $json->{'current'}->{'apparent_temperature'},
    });

    return $current_obj;
  }

  method get_forecast( Str $location ) {
    my $resolved = $self->convert_location($location);
    my $location_query_params = $self->_location($resolved->{'coordinates'});

    my $json = $self->_fetch_and_decode($self->_get_uri($location_query_params));
    
    my @days;
    foreach my $i (0..2) {
      my ($year, $month, $day) = split('-', $json->{'daily'}->{'time'}[$i]);
      my $dt = DateTime->new(
        'year' => $year,
        'month' => $month,
        'day' => $day,
      );
      my $high = $json->{'daily'}->{'temperature_2m_max'}[$i];
      my $low = $json->{'daily'}->{'temperature_2m_min'}[$i];
      my $f = Whatbot::Command::Weather::Forecast->new({
        'weekday'            => $dt->day_name(),
        'high_temperature_f' => $json->{'daily'}->{'temperature_2m_max'}[$i],
        'low_temperature_f'  => $json->{'daily'}->{'temperature_2m_min'}[$i],
        'conditions'       => $self->{'weather_codes_en'}->[$json->{'daily'}->{'weather_code'}[$i]],
      });
      push(@days, $f);
    }

    return \@days;
  }

  method _location( ArrayRef $location ) {
    my $query;

    if ( $location->[0] != 0 and $location->[1] != 0 ) {
      $query = 'latitude=' . $location->[0] . '&longitude=' . $location->[1];
    } else {
      die 'Could not determine coordinates for that location';
    }

    return $query;
  }

  method _fetch_and_decode( Str $url ) {
    my $response = $self->ua->get($url);

    my $content = $response->decoded_content;

    return decode_json( $content );
  }

  method BUILD (...) {
    $self->{'weather_codes_en'} = [
      # No precipitation
      "Clear", #0
      "Mostly clear",
      "Partly cloudy",
      "Overcast",
      "Smoke",
      "Haze", #5
      "Dust (distant)",
      "Dust or sand",
      "Dust or sand whirls",
      "Dust or sand storm",
      "Mist", #10
      "Mist patches",
      "Thick mist",
      "Distant lightning",
      "Rain within sight",
      "Distant rain", #15
      "Rain nearby (but dry here)",
      "Dry thunderstorm",
      "Squall",
      "Funnel clouds",

      # Recent precipitation
      "Recent drizzle", #20
      "Recent rain", 
      "Recent snow",
      "Recent mixed rain and snow",
      "Recent freezing rain",
      "Recent rainshowers", #25
      "Recent snowshowers",
      "Recent hail",
      "Recent fog",
      "Recent thunderstorm",

      # Dust or sandstorm or blowing snow
      "Dust or sandstorm (decreasing)", #30
      "Dust or sandstorm",
      "Dust or sandstorm (increasing)",
      "Severe dust or sandstorm (decreasing)", 
      "Severe dust or sandstorm",
      "Severe dust or sandstorm (increasing)", #35
      "Low blowing snow",
      "Low, heavy blowing snowdrifts",
      "Blowing snow",
      "Heavy blowing snowdrifts",

      # Fog
      "Nearby or recent fog", #40
      "Patchy fog",
      "Fog (decreasing)",
      "Thick fog (decreasing)",
      "Fog",
      "Thick fog",
      "Fog (increasing)",
      "Thick fog (increasing)",
      "Rime-depositing fog",
      "Thick rime-depositing fog",

      # Precipitation: Drizzle
      "Patches of drizzle (decreasing)", #50
      "Drizzle (decreasing)",
      "Patches of drizzle",
      "Drizzle",
      "Patches of drizzle (increasing)",
      "Drizzle (increasing)",
      "Freezing drizzle",
      "Dense freezing drizzle",
      "Mixed drizzle and rain",
      "Heavy mixed drizzle and rain", #gross

      # Precipitation: Rain
      "Patches of rain (decreasing)", #60
      "Rain (decreasing)",
      "Patches of rain",
      "Rain",
      "Patches of rain (increasing)",
      "Rain (increasing)",
      "Freezing rain",
      "Heavy freezing rain",
      "Mixed rain and snow",
      "Heavy mixed rain and snow",

      # Precipitation: Snow
      "Intermittent snow (decreasing)", #70
      "Snow (decreasing)",
      "Intermittent snow",
      "Snow",
      "Intermittent snow (increasing)",
      "Snow (increasing)",
      "Diamond dust",
      "Snow grains",
      "Isolated star-like snow crystals", #lol
      "Ice pellets",

      # Precipitation: More rain
      "Light rain showers", # 80
      "Rain showers",
      "Violent rain showers",
      "Mixed rain and snow showers",
      "Mixed heavy rain and snow showers",
      "Snow showers", # 85
      "Heavy snow showers",
      "Showers of snow pellets or small hail",
      "Heavy showers of snow pellets or small hail",
      "Hail showers",
      "Heavy hail showers", #90
      "Light rain, recent thunderstorm",
      "Heavy rain, recent thunderstorm", 
      "Light snow or mix, recent thunderstorm",
      "Heavy snow or mix, recent thunderstorm",
      "Recent thunderstorm", #95
      "Thunderstorm with hail",
      "Heavy thunderstorm",
      "Thunderstorm with dust or sandstorm",
      "Heavy thunderstorm with hail" #99
    ];

  }
}

1;

=pod

=head1 NAME

Whatbot::Command::Weather::Openmeteo - Retrieve weather from the OpenMeteo API

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=head1 CONFIG

None.

=cut
