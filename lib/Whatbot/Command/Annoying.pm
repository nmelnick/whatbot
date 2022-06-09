###########################################################################
# Whatbot/Command/Annoying.pm
###########################################################################
# makes whatbot annoying
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Annoying;
use Moose;
BEGIN { extends 'Whatbot::Command'; }

use Acme::LOLCAT;
use namespace::autoclean;

our $VERSION = '0.1';

has be_annoying => ( is => 'rw', isa => 'Bool' );

sub register {
  my ($self) = @_;
  
  $self->command_priority('Last');
  $self->require_direct(0);
}

sub toggle : GlobalRegEx('^(don.t )?be annoying[\.\!]?$') {
  my ( $self, $message, $captures ) = @_;
  
  $self->be_annoying( $self->be_annoying ? 0 : 1 );
  return 'OK, I am ' . ( $self->be_annoying ? '' : 'no longer as ' ) . 'annoying.';
}

sub respond : GlobalRegEx('.') {
  my ( $self, $message ) = @_;
  
  return unless ( $self->be_annoying and not $message->content =~ /^(don.t )?be annoying[\.\!]?$/ );
  return $self->annoying( $message->content );
}

sub annoying {
  my ( $self, $content ) = @_;
  
  return translate($content);
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Whatbot::Command::Annoying - Continually be annoying.

=head1 DESCRIPTION

Whatbot::Command::Annoying parrots back any line in a chat with the same line
as run through Acme::LOLCAT. It is quite annoying, and toggleable.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
