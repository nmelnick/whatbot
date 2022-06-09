###########################################################################
# Whatbot/Command/Weather/ConvertRole.pm
###########################################################################
# Role providing temperature converter
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

role Whatbot::Command::Weather::ConvertRole {
  use Convert::Temperature;

  has 'conv' => (
    is      => 'ro',
    isa     => 'Convert::Temperature',
    default => sub { return Convert::Temperature->new(); },
  );

  method to_celsius( Num $temperature ) {
    return $self->conv->from_fahr_to_cel($temperature);
  }

  method temp_string( Num $temperature ) {
    return sprintf(
      '%d F (%0.2f C)',
      $temperature,
      $self->to_celsius($temperature)
    );
  }
}

1;

=pod

=head1 NAME

Whatbot::Command::Weather::ConvertRole - Role providing temperature converter

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
