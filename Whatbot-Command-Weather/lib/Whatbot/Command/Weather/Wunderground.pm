###########################################################################
# Whatbot/Command/Weather/Wunderground.pm
###########################################################################
# Retrieve weather from the Wunderground API
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class Whatbot::Command::Weather::Wunderground with Whatbot::Command::Weather::SourceRole {
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
			'http://api.wunderground.com/api/%s/%s/q/%s.json',
			$self->api_key,
			$command,
			$query
		);
	}

	method get_current( Str $location ) {
		my $query = $self->_location($location);

		unless ($query) {
			die 'Unwilling to figure out what you meant by: ' . $location;	
		}

		my $json = $self->_fetch_and_decode( $self->_get_uri( 'conditions/alerts', $query ) );

		if ( my $current = $json->{'current_observation'} ) {
			my $current_obj = Whatbot::Command::Weather::Current->new({
				'display_location' => $current->{'display_location'}->{'full'},
				'conditions'       => $current->{'weather'},
				'temperature_f'    => $current->{'temp_f'},
				'feels_like_f'     => $current->{'feelslike_f'},

			});
			if ( $json->{'alerts'} and @{ $json->{'alerts'} } ) {
				foreach ( @{ $json->{'alerts'} } ) {
					$current_obj->add_alert( $_->{'description'} );
				}
			}
			return $current_obj;
		}
		return;
	}

	method get_forecast( Str $location ) {
		my $query = $self->_location($location);

		unless ($query) {
			die 'Unwilling to figure out what you meant by: ' . $location;	
		}

		my $json = $self->_fetch_and_decode( $self->_get_uri( 'forecast', $query ) );
		return unless ( $json and ref($json) and $json->{'forecast'} );

		my $forecasts = $json->{'forecast'}->{'simpleforecast'}->{'forecastday'};

		my @days;
		foreach my $forecast ( @$forecasts ) {
			push(
				@days,
				Whatbot::Command::Weather::Forecast->new({
					'weekday'            => $forecast->{'date'}->{'weekday'},
					'conditions'         => $forecast->{'conditions'},
					'high_temperature_f' => $forecast->{'high'}->{'fahrenheit'},
					'low_temperature_f'  => $forecast->{'low'}->{'fahrenheit'},
				})
			)
		}

		return \@days;
	}

	method _location( Str $location ) {
		my $query;

		if ( $location =~ /^\d{5}$/ ) {
			$query = $location;
		} elsif ( $location =~ /([^,]+), (\w\w+)/ ) {
			$query = $2 . '/' . $1;
		} elsif ( $location =~ /([^,]+), (\w{2})/ ) {
			$query = $2 . '/' . $1;
		}

		return $query;
	}

	method _fetch_and_decode( Str $url ) {
		my $response = $self->ua->get($url);
		my $content = $response->decoded_content;

		# Nothing is compliant, so if headers appear in the response, separate them.
		if ( $content =~ /Content\-Type/ ) {
			my ( $headers, @contents ) = split( /\n\n/, $content );
			$content = join( '', @contents );
			$content =~ s/\s*0\s*$//;
		}

		# What the eff, wunderground
		$content =~ s/\s+ef1\s+//g;

		return decode_json( $content );
	}

}

1;

=pod

=head1 NAME

Whatbot::Command::Weather::Wunderground - Retrieve weather from the Wunderground API

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
