use Moops;

class Whatbot::Command::Blackjack::Hand {
    has 'player'    => ( is => 'rw', isa => 'Str' );
    has 'cards'     => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
    has 'last_draw' => ( is => 'rw', isa => 'Int', default => 0 );

    method clone() {        
        return Whatbot::Command::Blackjack::Hand->new(
            'player' => $self->player
        );
    }

    method fingerprint() {        
        return join( '',
            $self->player,
            $self->first->value,
            $self->first->suit,
            $self->second->value,
            $self->second->suit
        );
    }

    method ircize() {        
        my $output = $self->player . ': ';
        foreach my $card ( @{ $self->cards } ) {
            $output .= $card->ircize . '  ';
        }
        $output .= '(' . $self->score . ').';
        
        return $output;
    }

    method first() {        
        return $self->cards->[0];
    }

    method second() {        
        return $self->cards->[1];
    }

    method give($card) {
        push( @{ $self->cards }, $card );
    }

    method busted() {        
        return ( $self->score > 21 ? 1 : 0 );
    }

    method blackjack() {        
        return ( $self->score == 21 and $self->card_count == 2 );
    }

    method card_count() {        
        return scalar( @{ $self->cards } );
    }

    method has_ace() {        
        foreach my $card ( @{ $self->cards } ) {
            return 1 if ( $card->value eq 'A' );
        }
        return;
    }

    method can_double() {        
        return ( $self->card_count == 2 and $self->score > 8 and $self->score < 12 ? 1 : 0 );
    }

    method can_split() {        
        return ( $self->card_count == 2 and $self->first->value eq $self->second->value ? 1 : 0 );
    }

    method score() {        
        my $score = 0;
        my @aces;
        foreach my $card ( @{ $self->cards } ) {
            if ( $card->value =~ /[KQJ]/ ) {
                $score += 10;
            } elsif ( $card->value eq 'A' ) {
                push( @aces, $card );
            } else {
                $score += $card->value
            }
        }
        foreach my $ace ( @aces ) {
            $score += 1;
        }
        foreach my $ace ( @aces ) {
            if ( $score + 10 <= 21 ) {
                $score += 10;
            }
        }
        
        return $score;
    }
}

1;