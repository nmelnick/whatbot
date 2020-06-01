###########################################################################
# Whatbot/Command/Weather/Climacell.pm
###########################################################################
# Retrieve weather from the Climacell API
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::Command::Weather::Climacell with Whatbot::Command::Weather::SourceRole {
    use DateTime;
    use Geo::Coder::OSM;
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
            'https://api.climacell.co/v3/weather/%s?unit_system=us&apikey=%s&%s',
            $command,
            $self->api_key,
            $query
        );
    }

    method get_current( Str $location ) {
        my $resolved = $self->_resolve_location_string($location);
        my $query = $self->_location($resolved->{'coordinates'});

        my $json = $self->_fetch_and_decode(
            $self->_get_uri( 'realtime', $query ) . '&fields=temp%2Cfeels_like%2Cweather_code'
        );
        if ( $json->{'temp'} ) {
            my $summary = ucfirst($json->{'weather_code'}->{'value'});
            $summary =~ s/_/ /g;
            my $current_obj = Whatbot::Command::Weather::Current->new({
                'display_location' => $resolved->{'display'},
                'conditions'       => $summary,
                'temperature_f'    => $json->{'temp'}->{'value'},
                'feels_like_f'     => $json->{'feels_like'}->{'value'},

            });
            return $current_obj;
        }
        return;
    }

    method get_forecast( Str $location ) {
        my $resolved = $self->_resolve_location_string($location);
        my $query = $self->_location($resolved->{'coordinates'});

        my $date = DateTime->now()->add( days => 3 );
        my $json = $self->_fetch_and_decode(
            $self->_get_uri( 'forecast/daily', $query ) . '&start_time=now&end_time=' . $date->iso8601() . '&fields=temp%2Cweather_code'
        );
        return unless ( $json and ref($json) );

        my @days;
        foreach my $forecast (@{$json}[0..2]) {
            my $summary = ucfirst($forecast->{'weather_code'}->{'value'});
            $summary =~ s/_/ /g;
            my ($year, $month, $day) = split('-', $forecast->{'observation_time'}->{'value'});
            my $dt = DateTime->new(
                'year' => $year,
                'month' => $month,
                'day' => $day,
            );
            my $high = $forecast->{'temp'}->[0]->{'max'} ? $forecast->{'temp'}->[0]->{'max'}->{'value'} : $forecast->{'temp'}->[1]->{'max'}->{'value'};
            my $low = $forecast->{'temp'}->[0]->{'min'} ? $forecast->{'temp'}->[0]->{'min'}->{'value'} : $forecast->{'temp'}->[1]->{'min'}->{'value'};
            my $f = Whatbot::Command::Weather::Forecast->new({
                'weekday'            => $dt->day_name(),
                'high_temperature_f' => $high,
                'low_temperature_f'  => $low,
                'conditions'         => $summary,
            });
            push(@days, $f);
        }

        return \@days;
    }

    method _location( Str $location ) {
        my $query;

        if ( $location =~ /^(\-?[\d\.]+), ?(\-?[\d\.]+)$/ ) {
            $query = "lat=$1&lon=$2";
        } else {
            die 'Unwilling to figure out what you meant by "' . $location . '"';
        }

        return $query;
    }

    method _resolve_location_string( Str $location ) {
        if ( $location =~ /,/ or $location =~ /^\d+$/ ) {
            my $osm = Geo::Coder::OSM->new();
            my $resolved = $osm->geocode( location => $location );
            if ($resolved and $resolved->{'lat'}) {
                return {
                    'coordinates' => join( ',', $resolved->{'lat'}, $resolved->{'lon'} ),
                    'display'     => join( ', ',
                        ( $resolved->{'address'}->{'city'} or $resolved->{'address'}->{'town'} ),
                        $resolved->{'address'}->{'state'},
                        $resolved->{'address'}->{'country'}
                    ),
                };
            }
        }
        
        return {
            'coordinates' => $location,
            'display'     => $location,
        };
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

Whatbot::Command::Weather::Climacell - Retrieve weather from the Dark Sky API

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
