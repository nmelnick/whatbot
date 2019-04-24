use Moops;

class Whatbot::Command::Blackjack::Stack::Deck extends Whatbot::Command::Blackjack::Stack {
    use Whatbot::Command::Blackjack::Card;

    method BUILD(...) {
        my @cards;
        my @suits = keys %{ Whatbot::Command::Blackjack::Constants::suits() };
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
}

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