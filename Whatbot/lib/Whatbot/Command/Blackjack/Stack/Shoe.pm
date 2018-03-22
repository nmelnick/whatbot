use Moops;

class Whatbot::Command::Blackjack::Stack::Shoe extends Whatbot::Command::Blackjack::Stack {
    use Whatbot::Command::Blackjack::Stack::Deck;

    has 'decks'   => ( is => 'rw', isa => 'Int', default => 4 );

    method BUILD(...) {
        my @cards;
        foreach ( 1 .. $self->decks ) {
            my $deck = Whatbot::Command::Blackjack::Stack::Deck->new();
            push( @cards, @{ $deck->cards } );
        }
        $self->cards(\@cards);
        $self->shuffle();
        $self->shuffle();
    }
}

1;

=pod

=head1 NAME

Whatbot::Command::Blackjack::Stack::Shoe - Represents an card shoe

=head1 DESCRIPTION

Represents a standard shoe of cards. Defaults to five decks.

=head1 PUBLIC ACCESSORS

=over 4

=item decks

Number of decks in the shoe.

=back

=head1 INHERITANCE

=over 4

=item Whatbot::Command::Blackjack::Stack

=over 4

=item Whatbot::Command::Blackjack::Stack::Shoe

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut