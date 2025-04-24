###########################################################################
# Whatbot/Command/Weather.pm
###########################################################################
# Get a simple weather report
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Weather;
use Moose;
BEGIN { extends 'Whatbot::Command'; }
use namespace::autoclean;
use Class::Load;
use Try::Tiny;

our $VERSION = '0.2';

has 'source' => (
  'is'   => 'rw',
  'does' => 'Whatbot::Command::Weather::SourceRole',
);

sub register {
  my ( $self ) = @_;
  
  $self->command_priority('Extension');
  $self->require_direct(0);

  if ( $self->my_config ) {
    if ( $self->my_config->{'source'} ) {
      my $class = 'Whatbot::Command::Weather::' . ucfirst( $self->my_config->{'source'} );
      my ( $success, $error ) = Class::Load::try_load_class($class);
      if ( $success ) {
        $self->source(
          $class->new( $self->my_config )
        );
      } else {
        $self->log->write( 'Invalid source: ' . $class . ': ' . $error );
      }
    } else {
      $self->log->write( 'Not adding weather extension, no source configured' );
    }
  }

  return;
}

sub forecast : GlobalRegEx('(?i)^forecast (.*)') {
  my ( $self, $message, $captures ) = @_;

  return unless ( $self->source );

  my $response;
  try {
    $response = $self->source->get_forecast( $captures->[0] );
  } catch {
    return $_;
  };

  if ( $response and ref($response) eq 'ARRAY' ) {
    return [ map { $_->to_string() } @$response ];
  }

  return 'Iunno.';
}

sub weather : GlobalRegEx('(?i)^weather (.*)') {
  my ( $self, $message, $captures ) = @_;
  
  return unless ( $self->source );

  my $response;
  try {
    $response = $self->source->get_current( $captures->[0] );
  } catch {
    return $_;
  };

  if ($response) {
    return $response->to_string();
  }

  return 'Iunno.';
}

sub help {
  my ( $self ) = @_;
  
  return [
    'Weather grabs the temperature and alerts for a zip code or "City, Country".',
    'Usage: weather 10101',
    'Usage: weather Toronto, Canada',
    'Usage: forecast 10101'
  ];
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Whatbot::Command::Weather - Get weather information for US and world

=head1 SYNOPSIS

Config:

"weather" : {
  "source"  : "wunderground",
  "api_key" : "12345678abcdef90"
}

=head1 DESCRIPTION

Whatbot::Command::Weather will use the Wunderground API to retrieve weather
information. To do this, you will need to sign up for a free API key from the
wunderground API site.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
