package whatbot::Command::Blackjack::Stack::Deck;
use Moose;
extends 'whatbot::Command::Blackjack::Stack';
use whatbot::Command::Blackjack::Card;

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
            my $card = new whatbot::Command::Blackjack::Card(
                'value' => $value,
                'suit'  => $suit
            );
            push( @cards, $card );
        }
    }
    $self->cards(\@cards);
    $self->shuffle();
}

1;

=pod

=head1 NAME

whatbot::Command::Blackjack::Stack::Deck - Represents a standard western 52-card deck

=head1 DESCRIPTION

Represents a standard deck of 52 cards.

=head1 INHERITANCE

=over 4

=item whatbot::Command::Blackjack::Stack

=over 4

=item whatbot::Command::Blackjack::Stack::Deck

=back

=back

=head1 LICENSE/COPYRIGHT

Undetermined at this time. :)

=cut