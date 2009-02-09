package whatbot::Command::Blackjack::Game;
use Moose;

use Clone 'clone';

use whatbot::Command::Blackjack::Stack::Shoe;
use whatbot::Command::Blackjack::Hand;

has 'players'       => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has 'bets'          => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has 'hands'         => ( is => 'rw', isa => 'ArrayRef' );
has 'shoe'          => ( is => 'rw', isa => 'whatbot::Command::Blackjack::Stack::Shoe' );
has 'active_shoe'   => ( is => 'rw', isa => 'Int', default => 0 );

sub add_player {
    my ( $self, $player, $buy_in ) = @_;
    
    return if ( $self->players->{$player} );
    $self->players->{$player} = $buy_in;
    
    return 1;
}

sub remove_player {
    my ( $self, $player ) = @_;
    
    delete( $self->players->{$player} );
    return 1;
}

sub start {
    my ( $self, $options ) = @_;
    
    return unless ( $options and $options->{'players'} );
    
    $options->{'buy_in'} ||= 100;
    
    foreach my $player ( @{ $options->{'players'} } ) {
        $self->add_player( $player, $options->{'buy_in'} );
    }
    
    return $self->reshoe();
}

sub reshoe {
    my ( $self ) = @_;
    
    $self->shoe( new whatbot::Command::Blackjack::Stack::Shoe ( 'decks' => 4 ) );
    $self->active_shoe(1);
    
    return;
}

sub deal {
    my ( $self, $players ) = @_;
    
    my @hands;
    my $dealer_hand = new whatbot::Command::Blackjack::Hand (
        'player'    => 'Dealer',
        'game'      => $self
    );
    push( @hands, $dealer_hand );
    $self->{'bets'} = {};
    foreach my $player ( keys %{$players} ) {
        $self->bets->{$player} = $players->{$player};
        $self->players->{ $player } -= $players->{$player};
        
        my $hand = new whatbot::Command::Blackjack::Hand (
            'player'    => $player,
            'game'      => $self
        );
        push( @hands, $hand );
    }
    for ( 1 .. 2 ) {
        foreach my $hand ( @hands ) {
            $self->hit($hand);
        }
    }
    
    if ( $self->shoe->card_count < ( scalar(keys %{$self->players}) * 3 ) ) {
        $self->active_shoe(0);
    }
    
    warn Data::Dumper::Dumper( $self->players );
    $self->hands(\@hands);
    return clone( \@hands );
}

sub collect_hand {
    my ( $self, $hand ) = @_;
    
    my $index = $self->find_hand($hand);
    return if ( $index < 0 );
    
    $self->hands->[$index] = $hand;
    return 1;
}

sub finish_hand {
    my ( $self ) = @_;
    
    return unless ( $self->hands );
    
    my $dealer = shift(@{ $self->hands });
    return unless $dealer;
    
    my $dealer_score = $dealer->score;
    $dealer_score += 10 if ( $dealer->has_ace and $dealer->score < 12 );
    foreach my $hand (@{ $self->hands }) {
        my $score = $hand->score;
        $score += 10 if ( $hand->has_ace and $hand->score < 12 );
        warn sprintf( '%s: dealer %d, player %d', $hand->player, $dealer_score, $score );
        if ( $hand->busted ) {
            next;
        } elsif ( $dealer->busted ) {
            $self->players->{ $hand->player } += $self->bets->{ $hand->player } * 2;
        } elsif ( $score eq $dealer_score ) {
            $self->players->{ $hand->player } += $self->bets->{ $hand->player };
        } elsif ( $score > $dealer_score ) {
            $self->players->{ $hand->player } += $self->bets->{ $hand->player } * 2;
        } elsif ( $hand->blackjack ) {
            $self->players->{ $hand->player } += $self->bets->{ $hand->player } * 2.5;
        }
    }
    return 1;
}

sub hit {
    my ( $self, $hand ) = @_;
    
    $hand->give( $self->shoe->take() );
}

sub can_split {
    my ( $self, $hand ) = @_;
    
    return 1 if ( $hand->can_split and $self->players->{ $hand->player } >= $self->bets->{ $hand->player } );
    return;
}

sub split {
    my ( $self, $hand ) = @_;
    
    return unless ( $self->can_split );
    $self->players->{ $hand->player } -= $self->bets->{ $hand->player };
    $self->bets->{ $hand->player } *= 2;
    
    # Create first hand with first card
    my $first_hand = $hand->clone();
    $first_hand->give( $hand->first );
    $self->hit( $first_hand );
    
    # Create second hand with second card
    my $second_hand = $hand->clone();
    $second_hand->give( $hand->second );
    $self->hit( $second_hand );
    
    # Insert new hand into cached hands
    push( @{$self->hands}, $second_hand );
    
    return ( $first_hand, $second_hand );
}

sub can_double {
    my ( $self, $hand ) = @_;
    
    return 1 if ( $hand->can_double and $self->players->{ $hand->player } >= $self->bets->{ $hand->player } );
    return;
}

sub double {
    my ( $self, $hand ) = @_;
    
    return unless ( $self->can_double($hand) );
    $self->players->{ $hand->player } -= $self->bets->{ $hand->player };
    $self->bets->{ $hand->player } *= 2;
    $self->hit($hand);
}

sub find_hand {
    my ( $self, $hand ) = @_;
    
    my $hand_index = -1;
    for( my $i = 0; $i < scalar( @{ $self->hands } ); $i++ ) {
        if ( $hand->fingerprint eq $self->hands->[$i]->fingerprint ) {
            $hand_index = $i;
            last;
        }
    }
    
    return $hand_index;
}

sub dealer_hand {
    my ( $self, $hand ) = @_;
    
    return unless ( $hand->player eq 'Dealer' and !$hand->blackjack );
    
    while ( $hand->score < 17 ) {
        $self->hit($hand);
    }
    
    $self->collect_hand($hand);
    
    return 1;
}

1;