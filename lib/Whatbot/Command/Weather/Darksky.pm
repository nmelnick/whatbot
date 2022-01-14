###########################################################################
# Whatbot/Command/Weather/Darksky.pm
###########################################################################
# Retrieve weather from the Darksky API
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::Command::Weather::Darksky
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
        return sprintf(
            'https://api.darksky.net/%s/%s/%s?units=us',
            $command,
            $self->api_key,
            $query
        );
    }

    method get_current( Str $location ) {
        my $resolved = $self->convert_location($location);
        my $query = $self->_location($resolved->{'coordinates'});

        my $json = $self->_fetch_and_decode(
            $self->_get_uri( 'forecast', $query ) . '&exclude=minutely,hourly,daily'
        );

        if ( $json->{'currently'} ) {
            my $current_obj = Whatbot::Command::Weather::Current->new({
                'display_location' => $resolved->{'display'},
                'conditions'       => $json->{'currently'}->{'summary'},
                'temperature_f'    => $json->{'currently'}->{'temperature'},
                'feels_like_f'     => $json->{'currently'}->{'apparentTemperature'},

            });
            if ($json->{'alerts'} and @{$json->{'alerts'}}) {
                map {
                    $current_obj->add_alert($_->{'title'});
                } @{$json->{'alerts'}};
            }
            return $current_obj;
        }
        return;
    }

    method get_forecast( Str $location ) {
        my $resolved = $self->convert_location($location);
        my $query = $self->_location($resolved->{'coordinates'});

        my $json = $self->_fetch_and_decode(
            $self->_get_uri( 'forecast', $query ) . '&exclude=currently,minutely,hourly'
        );
        return unless ( $json and ref($json) and $json->{'daily'} );

        my @days;
        foreach my $forecast (@{$json->{'daily'}->{'data'}}[0..2]) {
            my $dt = DateTime->from_epoch(
                'epoch'     => $forecast->{'time'},
                'time_zone' => $json->{'timezone'},
            );
            my $f = Whatbot::Command::Weather::Forecast->new({
                'weekday'            => $dt->day_name(),
                'high_temperature_f' => $forecast->{'temperatureHigh'},
                'low_temperature_f'  => $forecast->{'temperatureLow'},
                'conditions'         => $forecast->{'summary'},
            });
            push(@days, $f);
        }

        return \@days;
    }

    method _location( ArrayRef $location ) {
        my $query;

        if ( $location->[0] != 0 and $location->[1] != 0 ) {
            $query = join( ',', @$location );
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

Whatbot::Command::Weather::Darksky - Retrieve weather from the Dark Sky API

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
