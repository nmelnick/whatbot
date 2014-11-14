package Whatbot::Command::Blackjack::Card;
use Moose;
use namespace::autoclean;
use Whatbot::Command::Blackjack::Constants;

has 'value'   => ( is => 'rw' );
has 'color'   => ( is => 'rw', isa => 'Str' );
has 'unicode' => ( is => 'rw', isa => 'Str' );
has 'suit'    => ( is => 'rw', isa => 'Str', trigger => sub {
    my $self = shift;
    $self->color( Whatbot::Command::Blackjack::Constants::suits()->{ $self->suit }->{'color'} );
    $self->unicode( Whatbot::Command::Blackjack::Constants::suits()->{ $self->suit }->{'uni'} );
} );

sub ircize {
    my ( $self ) = @_;
    
    my $string = $self->value . $self->unicode;
    return $string;
}

__PACKAGE__->meta->make_immutable;

1;