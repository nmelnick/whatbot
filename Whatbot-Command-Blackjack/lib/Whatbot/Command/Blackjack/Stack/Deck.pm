package Whatbot::Command::Blackjack::Stack::Deck;
use Moose;
extends 'Whatbot::Command::Blackjack::Stack';
use Whatbot::Command::Blackjack::Card;
use namespace::autoclean;

sub BUILD {
    my ( $self ) = @_;
    
    my @cards;
    my @suits = qw/
        diamonds
        hearts
        clubs
        spades
    /;
    foreach my $suit (@suits) {
        foreach my $value ( 'A', 2 .. 10, qw/ J Q K / )  {
            my $card = Whatbot::Command::Blackjack::Card->new(
                'value' => $value,
                'suit'  => $suit
            );
            push( @cards, $card );
        }
    }
    $self->cards(\@cards);
    $self->shuffle();
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Whatbot::Command::Blackjack::Stack::Deck - Represents a standard western 52-card deck

=head1 DESCRIPTION

Represents a standard deck of 52 cards.

=head1 INHERITANCE

=over 4

=item Whatbot::Command::Blackjack::Stack

=over 4

=item Whatbot::Command::Blackjack::Stack::Deck

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut