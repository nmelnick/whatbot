package whatbot::Command::Blackjack::Card;
use Moose;
use namespace::autoclean;
use whatbot::Command::Blackjack::Constants;

has 'value'   => ( is => 'rw' );
has 'color'   => ( is => 'rw', isa => 'Str' );
has 'unicode' => ( is => 'rw', isa => 'Str' );
has 'suit'    => ( is => 'rw', isa => 'Str', trigger => sub {
    my $self = shift;
    $self->color( whatbot::Command::Blackjack::Constants::suits()->{ $self->suit }->{'color'} );
    $self->unicode( whatbot::Command::Blackjack::Constants::suits()->{ $self->suit }->{'uni'} );
} );

sub ircize {
    my ( $self ) = @_;
    
    my $string = $self->value . $self->unicode;
    return $string;
}

__PACKAGE__->meta->make_immutable;

1;