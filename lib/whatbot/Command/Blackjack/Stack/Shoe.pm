package whatbot::Command::Blackjack::Stack::Shoe;
use Moose;
extends 'whatbot::Command::Blackjack::Stack';
use whatbot::Command::Blackjack::Stack::Deck;

has 'decks'   => ( is => 'rw', isa => 'Int', default => 4 );

sub BUILD {
    my ( $self ) = @_;
    
    my @cards;
    foreach ( 1 .. $self->decks ) {
        my $deck = new whatbot::Command::Blackjack::Stack::Deck;
        foreach my $card ( @{ $deck->cards } ) {
            push( @cards, $card );
        }
    }
    $self->cards(\@cards);
    $self->shuffle();
    $self->shuffle();
}

1;

=pod

=head1 NAME

whatbot::Command::Blackjack::Stack::Shoe - Represents an card shoe

=head1 DESCRIPTION

Represents a standard shoe of cards. Defaults to five decks.

=head1 PUBLIC ACCESSORS

=over 4

=item decks

Number of decks in the shoe.

=back

=head1 INHERITANCE

=over 4

=item whatbot::Command::Blackjack::Stack

=over 4

=item whatbot::Command::Blackjack::Stack::Shoe

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut