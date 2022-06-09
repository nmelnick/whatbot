###########################################################################
# Whatbot/Command/Weather/Openweathermap.pm
###########################################################################
# Retrieve weather from the Openweathermap API
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::Command::Weather::Openweathermap with Whatbot::Command::Weather::SourceRole {
  use JSON::XS;
  use Whatbot::Command::Weather::Current;
  use Whatbot::Command::Weather::Forecast;

  has 'api_key' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
  );

  method _get_uri( Str $command, Str $query ) {
    return sprintf(
      'https://api.openweathermap.org/data/2.5/%s?units=imperial&APPID=%s&%s',
      $command,
      $self->api_key,
      $query
    );
  }

  method get_current( Str $location ) {
    my $query = $self->_location($location);

    my $json = $self->_fetch_and_decode(
      $self->_get_uri( 'weather', $query )
    );

    if ( $json->{'name'} ) {
      my $current_obj = Whatbot::Command::Weather::Current->new({
        'display_location' => $json->{'name'},
        'conditions'       => $json->{'weather'}->[0]->{'description'},
        'temperature_f'    => $json->{'main'}->{'temp'},
      });
      return $current_obj;
    }
    return;
  }

  method get_forecast( Str $location ) {
    my $query = $self->_location($location);

    my $json = $self->_fetch_and_decode( $self->_get_uri( 'forecast', $query ) );
    return unless ( $json and ref($json) and $json->{'city'} );

    my %seen_dates;
    foreach my $forecast (@{$json->{'list'}}) {
      my $date = substr( $forecast->{'dt_txt'}, 0, 10 );
      $seen_dates{$date} ||= Whatbot::Command::Weather::Forecast->new({
        'weekday' => $date
      });
      if ( not $seen_dates{$date}->high_temperature_f or $seen_dates{$date}->high_temperature_f < $forecast->{'main'}->{'temp_max'} ) {
        $seen_dates{$date}->high_temperature_f($forecast->{'main'}->{'temp_max'});
      }
      if ( not $seen_dates{$date}->low_temperature_f or $seen_dates{$date}->low_temperature_f > $forecast->{'main'}->{'temp_min'} ) {
        $seen_dates{$date}->low_temperature_f($forecast->{'main'}->{'temp_min'});
      }
      if ( $seen_dates{$date}->conditions !~ $forecast->{'weather'}->[0]->{'description'} ) {
        if ( $seen_dates{$date}->conditions ) {
          $seen_dates{$date}->conditions( $seen_dates{$date}->conditions . ', ' );
        }
        $seen_dates{$date}->conditions( $seen_dates{$date}->conditions . $forecast->{'weather'}->[0]->{'description'} );
      }
    }

    my @days = map { $seen_dates{$_} } (sort { $a cmp $b } keys %seen_dates)[0..2];

    return \@days;
  }

  method _location( Str $location ) {
    my $query;

    if ( $location =~ /^\d{5}$/) {
      $query = 'zip=' . $location;
    } elsif ( $location =~ /^([^,]+), (\w{2})/ ) {
      my $city = $1;
      my $country = $2;
      $city =~ s/ /%20/g;
      $query = 'q=' . $city . ',' . $country;
    } else {
      die 'Unwilling to figure out what you meant by "' . $location . '"';
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

Whatbot::Command::Weather::Openweathermap - Retrieve weather from the OpenWeatherMap API

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
