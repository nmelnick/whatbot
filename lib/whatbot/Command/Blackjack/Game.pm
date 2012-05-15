package whatbot::Command::Blackjack::Game;
use Moose;

use Clone 'clone';

use whatbot::Command::Blackjack::Stack::Shoe;
use whatbot::Command::Blackjack::Hand;
use namespace::autoclean;

has 'players'       => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has 'bets'          => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
has 'hands'         => ( is => 'rw', isa => 'ArrayRef' );
has 'shoe'          => ( is => 'rw', isa => 'whatbot::Command::Blackjack::Stack::Shoe' );
has 'active_shoe'   => ( is => 'rw', isa => 'Int', default => 0 );

sub player {
    my ( $self, $player_name ) = @_;
    
    return defined $self->players->{$player_name} ? sprintf( '%.02f', $self->players->{$player_name} / 100 ) : undef;
}

sub player_dump {
    my ( $self ) = @_;
    
    foreach my $player ( keys %{ $self->players } ) {
        print $player . ' has ' . $self->players->{$player} . ' or ' . $self->player($player) . ( $self->bets->{$player} ? ' with active bet of ' . $self->bets->{$player} : '') . "\n";
    }
}

sub add_player {
    my ( $self, $player, $buy_in ) = @_;
    
    return if ( $self->players->{$player} );
    $self->players->{$player} = int( $buy_in * 100 );
    
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
    
    $self->shoe( whatbot::Command::Blackjack::Stack::Shoe->new( 'decks' => 4 ) );
    $self->active_shoe(1);
    
    return;
}

sub deal {
    my ( $self, $players ) = @_;
    
    my @hands;
    my $dealer_hand = whatbot::Command::Blackjack::Hand->new(
        'player'    => 'Dealer'
    );
    push( @hands, $dealer_hand );
    $self->{'bets'} = {};
    foreach my $player ( keys %{$players} ) {
        my $bet = int( $players->{$player} * 100 );
        next if ( !defined $self->players->{$player} or $bet < 1 );
        $self->bets->{$player} = $bet;
        $self->players->{ $player } -= $bet;
        
        my $hand = whatbot::Command::Blackjack::Hand->new(
            'player'    => $player
        );
        push( @hands, $hand );
    }
    return unless ( scalar(@hands) > 1 );
    
    for ( 1 .. 2 ) {
        foreach my $hand ( @hands ) {
            $self->hit($hand);
        }
    }
    
    if ( $self->shoe->card_count < ( scalar(keys %{$self->players}) * 3 ) ) {
        $self->active_shoe(0);
    }
    
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
    
    foreach my $hand (@{ $self->hands }) {
        if ( $hand->busted ) {
            next;
        } elsif ( $dealer->busted ) {
            $self->players->{ $hand->player } += int( $self->bets->{ $hand->player } * 2 );
        } elsif ( $hand->score eq $dealer->score ) {
            $self->players->{ $hand->player } += int( $self->bets->{ $hand->player } );
        } elsif ( $hand->blackjack ) {
            my $score = $self->bets->{ $hand->player } * 2.5;
            $self->players->{ $hand->player } += int($score);
        } elsif ( $hand->score > $dealer->score ) {
            $self->players->{ $hand->player } += int( $self->bets->{ $hand->player } * 2 );
        }
    }
    
    foreach my $player ( keys %{ $self->players } ) {
        $self->players->{$player} = 0 if ( $self->players->{$player} < 1 );
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
    
    return unless ( $self->can_split($hand) );
    $self->players->{ $hand->player } -= int( $self->bets->{ $hand->player } );
    
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
    my $bet = int( $self->bets->{ $hand->player } );
    $self->players->{ $hand->player } -= $bet;
    $self->bets->{ $hand->player } += $bet;
    $hand->last_draw(1);
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

__PACKAGE__->meta->make_immutable;

1;