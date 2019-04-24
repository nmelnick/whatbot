###########################################################################
# Whatbot/Command/Weather/Forecast.pm
###########################################################################
# Represents condition forecast for a single day
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::Command::Weather::Forecast with Whatbot::Command::Weather::ConvertRole {
	has 'weekday'            => ( is  => 'rw', isa => 'Str' );
	has 'conditions'         => ( is  => 'rw', isa => 'Str' );
	has 'high_temperature_f' => ( is  => 'rw', isa => 'Num' );
	has 'low_temperature_f'  => ( is  => 'rw', isa => 'Num' );

	method high_temperature_c() {
		return $self->to_celsius( $self->temperature_f );
	}

	method low_temperature_c() {
		return $self->to_celsius( $self->feels_like_f );
	}

	method to_string() {
		return sprintf(
			'%s: %s [H: %s, L: %s]', 
			$self->weekday,
			$self->conditions,
			$self->temp_string( $self->high_temperature_f ),
			$self->temp_string( $self->low_temperature_f ),
		);
	}

}

1;

=pod

=head1 NAME

Whatbot::Command::Weather::Forecast - Represents condition forecast for a single day

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
