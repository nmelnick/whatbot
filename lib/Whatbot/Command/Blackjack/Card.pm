use Moops;

class Whatbot::Command::Blackjack::Card {
  use Whatbot::Command::Blackjack::Constants;

  has 'value'   => ( is => 'rw' );
  has 'color'   => ( is => 'rw', isa => 'Str' );
  has 'unicode' => ( is => 'rw', isa => 'Str' );
  has 'suit'    => ( is => 'rw', isa => 'Str', trigger => sub {
    my $self = shift;
    my $suits = Whatbot::Command::Blackjack::Constants::suits();
    $self->color( $suits->{ $self->suit }->{'color'} );
    $self->unicode( $suits->{ $self->suit }->{'uni'} );
  } );

  method ircize() {
    return $self->value . $self->unicode;
  }
}

1;
