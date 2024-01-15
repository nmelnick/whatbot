###########################################################################
# Whatbot/Command/Weather/Tomorrow.pm
###########################################################################
# Retrieve weather from the Tomorrow API
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::Command::Weather::Tomorrow
  with Whatbot::Command::Weather::SourceRole
  with Whatbot::Command::Role::Location {
  use DateTime;
  use JSON::XS;
  use Whatbot::Command::Weather::Current;
  use Whatbot::Command::Weather::Forecast;

  has 'api_key' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
  );

  method _get_uri( Str $command, Str $query ) {
    my $uri = sprintf(
      'https://api.tomorrow.io/v4/weather/%s?units=imperial&apikey=%s&%s',
      $command,
      $self->api_key,
      $query
    );
    warn $uri;
    return $uri;
  }

  method get_current( Str $location ) {
    my $resolved = $self->convert_location($location);
    my $query = $self->_location($resolved->{'coordinates'});

    my $json = $self->_fetch_and_decode(
      $self->_get_uri( 'realtime', $query )
    );
    if ( $json->{'data'}->{'values'} ) {
      my $values = $json->{'data'}->{'values'};
      my $current_obj = Whatbot::Command::Weather::Current->new({
        'display_location' => $resolved->{'display'},
        'conditions'       => $self->_get_summary($values->{'weatherCode'}),
        'temperature_f'    => $values->{'temperature'},
        'feels_like_f'     => $values->{'temperatureApparent'},
      });
      return $current_obj;
    }
    return;
  }

  method get_forecast( Str $location ) {
    my $resolved = $self->convert_location($location);
    my $query = $self->_location($resolved->{'coordinates'});

    my $json = $self->_fetch_and_decode(
      $self->_get_uri( 'forecast', $query ) . '&timesteps=daily'
    );
    return unless ( $json and ref($json) );

    my @days;
    foreach my $forecast_parent (@{$json->{'timelines'}->{'daily'}}[0..2]) {
      my $forecast = $forecast_parent->{'values'};
      my ($year, $month, $day) = split('-', substr( $forecast_parent->{'time'}, 0, 10 ));
      my $dt = DateTime->new(
        'year' => $year,
        'month' => $month,
        'day' => $day,
      );
      my $high = $forecast->{'temperatureMax'};
      my $low = $forecast->{'temperatureMin'};
      my $f = Whatbot::Command::Weather::Forecast->new({
        'weekday'            => $dt->day_name(),
        'high_temperature_f' => $high,
        'low_temperature_f'  => $low,
        'conditions'         => $self->_get_summary($forecast->{'weatherCodeMax'}),
      });
      push(@days, $f);
    }

    return \@days;
  }

  method _get_summary( Int $weather_code ) {
    my %code_map = (
      "0" => "Unknown",
      "1000" => "Clear, Sunny",
      "1100" => "Mostly Clear",
      "1101" => "Partly Cloudy",
      "1102" => "Mostly Cloudy",
      "1001" => "Cloudy",
      "2000" => "Fog",
      "2100" => "Light Fog",
      "4000" => "Drizzle",
      "4001" => "Rain",
      "4200" => "Light Rain",
      "4201" => "Heavy Rain",
      "5000" => "Snow",
      "5001" => "Flurries",
      "5100" => "Light Snow",
      "5101" => "Heavy Snow",
      "6000" => "Freezing Drizzle",
      "6001" => "Freezing Rain",
      "6200" => "Light Freezing Rain",
      "6201" => "Heavy Freezing Rain",
      "7000" => "Ice Pellets",
      "7101" => "Heavy Ice Pellets",
      "7102" => "Light Ice Pellets",
      "8000" => "Thunderstorm"
    );
    return $code_map{$weather_code}
  }

  method _location( ArrayRef $location ) {
    my $query;

    if ( $location->[0] != 0 and $location->[1] != 0 ) {
      $query = 'location=' . $location->[0] . ',' . $location->[1];
    } else {
      die 'Unwilling to figure out what you meant by that location';
    }

    return $query;
  }

  method _fetch_and_decode( Str $url ) {
    my $response = $self->ua->get($url);
    my $content = $response->decoded_content;

    return decode_json( $content );
  }

}

1;

=pod

=head1 NAME

Whatbot::Command::Weather::Tomorrow - Retrieve weather from the Tomorrow API

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
