use Moops;

class Whatbot::Command::Blackjack::Stack {
    has 'cards'   => ( is => 'rw', isa => 'ArrayRef' );
    has 'discard' => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );

    method shuffle() {
        my %seen;
        my @cards;
        my $stack_size = scalar( @{$self->cards} );
        while ( scalar( keys %seen ) < $stack_size ) {
            my $index = -1;
            while ( $index < 0 or $seen{$index} ) {
                $index = int( rand($stack_size) );
            }
            push( @cards, $self->cards->[$index] );
            $seen{$index} = 1;
        }
        $self->cards(\@cards);
    }

    method card_count() {
        return scalar( @{ $self->cards } );
    }

    method take() {
        my $card = shift(@{ $self->cards });
        push( @{ $self->discard }, $card );
        return $card;
    }
}

1;

=pod

=head1 NAME

Whatbot::Command::Blackjack::Stack - Represents an independent, arbitrary stack of cards

=head1 DESCRIPTION

Acts as a base class for a deck or a shoe to provide helper functions for a
stack of cards.

=head1 PUBLIC ACCESSORS

=over 4

=item cards

Array reference containing each card in the stack.

=back

=head1 PUBLIC METHODS

=over 4

=item shuffle()

Shuffles the cards in the cards array reference.

=item card_count()

Returns the current number of cards left in the stack.

=item take()

Pulls a card from the stack and returns it.

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut