use Moops;

class Whatbot::Command::Blackjack::Game {
	use Clone 'clone';
	use Whatbot::Command::Blackjack::Stack::Shoe;
	use Whatbot::Command::Blackjack::Hand;

	has 'players'      => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
	has 'bets'         => ( is => 'ro', isa => 'HashRef', default => sub { {} } );
	has 'player_order' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
	has 'hands'        => ( is => 'rw', isa => 'ArrayRef' );
	has 'shoe'         => ( is => 'rw', isa => 'Whatbot::Command::Blackjack::Stack::Shoe' );
	has 'active_shoe'  => ( is => 'rw', isa => 'Int', default => 0 );

	method player($player_name) {		
		return defined $self->players->{$player_name} ? sprintf( '%.02f', $self->players->{$player_name} / 100 ) : undef;
	}

	method player_dump() {		
		foreach my $player ( keys %{ $self->players } ) {
			print $player . ' has ' . $self->players->{$player} . ' or ' . $self->player($player) . ( $self->bets->{$player} ? ' with active bet of ' . $self->bets->{$player} : '') . "\n";
		}
	}

	method add_player($player, $buy_in) {		
		return if ( $self->players->{$player} );
		$self->players->{$player} = int( $buy_in * 100 );
		push( @{ $self->player_order }, $player );
		
		return 1;
	}

	method remove_player($player) {		
		delete( $self->players->{$player} );
		$self->player_order( [ ( grep { !/^$player$/ } @{ $self->player_order } ) ] );
		return 1;
	}

	method start($options?) {		
		return unless ( $options and $options->{'players'} );
		
		$options->{'buy_in'} ||= 100;
		
		foreach my $player ( @{ $options->{'players'} } ) {
			$self->add_player( $player, $options->{'buy_in'} );
		}
		
		return $self->reshoe();
	}

	method reshoe() {		
		$self->shoe( Whatbot::Command::Blackjack::Stack::Shoe->new( 'decks' => 4 ) );
		$self->active_shoe(1);
		
		return;
	}

	method deal($players) {		
		my @hands;
		my $dealer_hand = Whatbot::Command::Blackjack::Hand->new(
			'player' => 'Dealer'
		);
		push( @hands, $dealer_hand );
		$self->{'bets'} = {};
		foreach my $player ( @{ $self->player_order } ) {
			# Skip if player didn't bet this round
			next unless ( $players->{$player} );

			my $bet = int( $players->{$player} * 100 );
			next if ( !defined $self->players->{$player} or $bet < 1 );
			$self->bets->{$player} = $bet;
			$self->players->{ $player } -= $bet;
			
			my $hand = Whatbot::Command::Blackjack::Hand->new(
				'player' => $player
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

	method collect_hand($hand) {		
		my $index = $self->find_hand($hand);
		return if ( $index < 0 );
		
		$self->hands->[$index] = $hand;
		return 1;
	}

	method finish_hand() {		
		return unless ( $self->hands );
		
		my $dealer = shift(@{ $self->hands });
		return unless $dealer;
		
		foreach my $hand (@{ $self->hands }) {
			if ( $hand->busted ) {
				next;
			} elsif ( $dealer->busted ) {
				$self->players->{ $hand->player } += int( $self->bets->{ $hand->player } * 2 );
			} elsif ( $hand->score eq $dealer->score and not $hand->blackjack ) {
				$self->players->{ $hand->player } += int( $self->bets->{ $hand->player } );
			} elsif ( $hand->blackjack ) {
				my $score = $self->bets->{ $hand->player } + ( $self->bets->{ $hand->player } * (3/2) );
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

	method hit($hand) {		
		$hand->give( $self->shoe->take() );
	}

	method can_split($hand) {		
		return 1 if ( $hand->can_split and $self->players->{ $hand->player } >= $self->bets->{ $hand->player } );
		return;
	}

	method split($hand) {		
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

	method can_double($hand) {		
		return 1 if ( $hand->can_double and $self->players->{ $hand->player } >= $self->bets->{ $hand->player } );
		return;
	}

	method double($hand) {		
		return unless ( $self->can_double($hand) );
		my $bet = int( $self->bets->{ $hand->player } );
		$self->players->{ $hand->player } -= $bet;
		$self->bets->{ $hand->player } += $bet;
		$hand->last_draw(1);
		$self->hit($hand);
	}

	method find_hand($hand) {		
		my $hand_index = -1;
		for( my $i = 0; $i < scalar( @{ $self->hands } ); $i++ ) {
			if ( $hand->fingerprint eq $self->hands->[$i]->fingerprint ) {
				$hand_index = $i;
				last;
			}
		}
		
		return $hand_index;
	}

	method dealer_hand($hand) {		
		return unless ( $hand->player eq 'Dealer' and !$hand->blackjack );
		
		while ( $hand->score < 17 ) {
			$self->hit($hand);
		}
		
		$self->collect_hand($hand);
		
		return 1;
	}
}

1;