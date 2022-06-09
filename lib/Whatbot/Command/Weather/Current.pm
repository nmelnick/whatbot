###########################################################################
# Whatbot/Command/Weather/Current.pm
###########################################################################
# Represents current conditions
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::Command::Weather::Current with Whatbot::Command::Weather::ConvertRole {
  has 'display_location' => ( is  => 'rw', isa => 'Str' );
  has 'conditions'       => ( is  => 'rw', isa => 'Str' );
  has 'temperature_f'    => ( is  => 'rw', isa => 'Str' );
  has 'feels_like_f'     => ( is  => 'rw', isa => 'Str' );

  has 'alerts' => (
    is  => 'ro',
    isa => 'ArrayRef',
    default => sub { [] },
    traits  => [ 'Array' ],
    handles => {
      'add_alert'     => 'push',
      'has_alerts'    => 'count',
      'unique_alerts' => 'uniq',
    },
  );

  method temperature_c() {
    return $self->to_celsius( $self->temperature_f );
  }

  method feels_like_c() {
    return $self->to_celsius( $self->feels_like_f );
  }

  method to_string() {
    return sprintf(
      'Weather for %s: Currently %s and %s%s. %s',
      $self->display_location,
      $self->conditions,
      $self->temp_string( $self->temperature_f ),
      (
        $self->feels_like_f ? 
          ', feels like ' . $self->temp_string( $self->feels_like_f )
          : ''
      ),
      (
        $self->has_alerts ?
          'Alerts: ' . join( ', ', $self->unique_alerts )
          : ''
      )
    );
  }

}

1;

=pod

=head1 NAME

Whatbot::Command::Weather::Current - Represents current conditions

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
