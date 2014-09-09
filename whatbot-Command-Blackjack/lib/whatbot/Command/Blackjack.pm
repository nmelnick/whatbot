###########################################################################
# whatbot/Command/Blackjack.pm
###########################################################################
# Play blackjack in a room
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Blackjack;
use Moose;
BEGIN { extends 'whatbot::Command' }

use whatbot::Command::Blackjack::Game;
use whatbot::Command::Insult;
use namespace::autoclean;

our $VERSION = '0.1';

has 'game'        => ( is => 'ro', isa => 'whatbot::Command::Blackjack::Game' );
has 'game_admin'  => ( is => 'rw', isa => 'Str' );
has 'bets'        => ( is => 'ro', isa => 'HashRef' );
has 'dealer_hand' => ( is => 'ro' );
has 'active_hand' => ( is => 'ro' );
has 'hands'       => ( is => 'ro', isa => 'ArrayRef' );
has 'buyin'       => ( is => 'rw', isa => 'Int', default => 100 );
has 'insult'      => ( is => 'ro', isa => 'whatbot::Command::Insult', handles => ['get_insult'], lazy_build => 1 );

sub _build_insult {
	my ($self) = @_;

	return $self->controller->command_short_name->{insult};
}

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub help : Command {
	my ( $self ) = @_;
	
	return [
		'Blackjack is a game of blackjack for whatbot. Hello, obvious. To ' .
		'begin, give the command "blackjack play". Blackjack will prompt ' .
		'you from there. To change the buy in, add that value after play.',
		'As a quick reference, once you initiate a game, enter "b me" to add ' .
		'yourself to a game, and the initater can do "b start" to start the ' .
		'game. At any time, you can type "b amounts" to see your holdings.',
		'You can add yourself to an existing game at any time by saying "b ' .
		'me".',
		'Standard rules. Double/Split offered, Blackjack pays 3:2, default ' .
		'buy in is $100.',
		'To end an existing game, give the command "blackjack end".'
	];
}

sub play : Command {
	my ( $self, $message, $buy_in ) = @_;
	
	return 'Blackjack game already active.' if ( $self->game );
	
	$self->game_admin( $message->from );
	
	$buy_in = shift( @$buy_in );
	$self->{'game'} = whatbot::Command::Blackjack::Game->new();
	$self->buyin($buy_in) if ($buy_in);
	
	return 'Blackjack time, buy in is $' . $self->buyin . '. Anyone who wants to play, type "b me". ' . $message->from . ', type "b start" when everyone is ready.';
}

sub add_player : GlobalRegEx('^bj? me$') {
	my ( $self, $message ) = @_;
	
	return unless ( $self->game );
	if ( $self->game->add_player( $message->from, $self->buyin ) ) {
		return 'Gotcha, ' . $message->from . '.';
	} else {
		return 'Already got you, ' . $message->from . $self->generate_insult;
	}
}

sub start : GlobalRegEx('^bj? start$') {
	my ( $self, $message ) = @_;
	
	return unless ( $self->game and $message->from eq $self->game_admin );
	unless ( keys %{ $self->game->players } ) {
		return 'I need players before you can deal' . $self->generate_insult;
	}
	
	$self->game->start({
		'buy_in' => $self->buyin
	});
	
	return $self->new_hand();
}

sub end : Command {
	my ( $self ) = @_;
	
	return unless ( $self->game );
	
	foreach my $attribute ( qw( game game_admin bets dealer_hand active_hand hands ) ) {
		$self->{$attribute} = undef;
	}
	$self->{'buyin'} = 100;
	$self->{'last_insult'} = 'rand';
	
	return 'Alright, fine, no more game for you.';
}

sub hax : Command {
	my ( $self, $message, $captures ) = @_;
	
	return unless ( $message->from eq $self->game_admin );
	my ( $player, $amount ) = split( ' ', $captures->[0] );
	return 'Player "' . $player . '" doesn\'t exist' . $self->generate_insult
		unless ( $player and $self->game->player($player) );
	return 'What is "' . $amount . '"' . $self->generate_insult
		unless ( $amount and $amount =~ /^\d+$/ );
	
	$self->game->players->{$player} = int( $amount * 100 );
	return 'Hax enabled. ' . $self->amounts();
}

sub amounts : GlobalRegEx('^bj? amounts') {
	my ( $self ) = @_;
	
	return 'Players: ' . join( ', ', map { $_ . ' with $' . ( $self->game->player($_) =~ /00$/ ? sprintf( '%.02f', $self->game->player($_) ) : $self->game->player($_) ) } keys %{ $self->game->players } )
}

sub new_hand {
	my ( $self, $messages ) = @_;
	
	my @messages;
	@messages = @$messages if ($messages);
	unless ( $self->game->active_shoe == 1 ) {
		push( @messages, 'We now have a new shoe of cards.' );
		$self->game->reshoe();
	}
	
	$self->game->finish_hand();
	
	$self->{'waiting_for_bets'}++;
	$self->{'bets'} = {};
	push( @messages, $self->amounts ) if ( $self->game->players );
	
	foreach my $player ( keys %{ $self->game->players } ) {
		if ( $self->game->players->{$player} == 0 ) {
			push( @messages, 'See ya later, ' . $player . '.' );
			$self->game->remove_player($player);
		}
	}
	
	unless ( keys %{ $self->game->players } ) {
		push( @messages, 'No more players. Good work' . $self->generate_insult(1) );
		$self->end();
		return \@messages;
	}
	push(
		@messages,
		'New hand: Place your bets by typing "b bet amount" where amount is '
		. 'your actual numeric bet. If you want to sit this out, hit b bet 0.'
	);
	
	return \@messages;
}

sub bet : GlobalRegEx('^bj? bet \$?(\d+(\.\d\d)?)$') {
	my ( $self, $message, $captures ) = @_;
	
	return unless ( $self->{'waiting_for_bets'} );
	
	my $bet = $captures->[0];
	return unless ( defined $bet );
	$bet = 0 if ( $bet < 0.01 );
	return 'You have not bought in, ' . $message->from . '.'
		unless ( $self->game->players->{ $message->from } );
	return 'You cannot bet $' . $bet . ', ' . $message->from . ', you only have $' . $self->game->player($message->from) . '.' unless ( $self->game->player($message->from) >= $bet );
	
	$self->bets->{ $message->from } = $bet;
	
	if ( keys %{ $self->bets } == keys %{ $self->game->players } ) {
		return $self->deal();
	}
	return 'Okay, ' . $message->from . '.';
}

sub deal : Command {
	my ( $self ) = @_;

	return unless ( $self->game and $self->game->active_shoe );
	$self->{'waiting_for_bets'} = 0;
	
	$self->{'hands'} = $self->game->deal( $self->bets );
	return $self->new_hand() unless ( $self->{'hands'} );
	$self->{'dealer_hand'} = shift( @{ $self->{'hands'} } );
	if ( $self->dealer_hand->blackjack ) {
		my @messages;
		foreach my $hand ( @{$self->hands} ) {
			push( @messages, $hand->ircize() );
		}
		push( @messages, $self->dealer_hand->ircize() );
		push( @messages, 'Dealer has Blackjack. Thank you for all of your money' . $self->generate_insult(1) );
		return $self->new_hand( \@messages );
	}
	my $dealer_view = 'Dealer shows ' . $self->dealer_hand->first->ircize . '.';
	return $self->next_hand([ $dealer_view ]);
}

sub next_hand {
	my ( $self, $messages ) = @_;
	
	my $hand = shift( @{ $self->hands } );
	
	# Check if last hand, if so, show dealer hand and cycle
	unless ($hand) {
		$messages = [] unless ($messages);
		$self->game->dealer_hand( $self->dealer_hand );
		my $output = $self->dealer_hand->ircize();
		if ( $self->dealer_hand->busted ) {
			$output .= ' Dealer busts.';
		} elsif ( $self->dealer_hand->score == 21 ) {
			$output .= ' WOO.';
		}
		push( @$messages, $output );
		return $self->new_hand($messages);
	}
	$self->{'active_hand'} = $hand;
	return $self->hand_action($messages);
}

sub hand_action {
	my ( $self, $messages ) = @_;
	
	my @messages;
	@messages = @$messages if ($messages);
	my $hand = $self->active_hand;
	my $output = $hand->ircize();
	if ( $hand->blackjack ) {
		$output .= ' Congratulations, you got blackjack.';
		push( @messages, $output );
		$self->game->collect_hand($hand);
		return $self->next_hand(\@messages);
	} elsif ( $hand->busted ) {
		$output .= ' Good job, you busted' . $self->generate_insult;
		push( @messages, $output );
		$self->game->collect_hand($hand);
		return $self->next_hand(\@messages);
	} elsif ( $hand->score == 21 ) {
		$output .= ' Hey, you didn\'t bust.';
		push( @messages, $output );
		$self->game->collect_hand($hand);
		return $self->next_hand(\@messages);
	} elsif ( $hand->last_draw ) {
		$output .= ' Enjoy your lots' . $self->generate_insult;
		push( @messages, $output );
		$self->game->collect_hand($hand);
		return $self->next_hand(\@messages);
	} else {
		$output .= ' Start with "b", then h/hit s/stand';
		$output .= ' d/double' if ( $self->game->can_double($hand) );
		$output .= ' p/split' if ( $self->game->can_split($hand) );
		$output .= '.';
		push( @messages, $output );
		return \@messages;
	}
	
}

sub hit : GlobalRegEx('^bj? (h|hit)$') {
	my ( $self, $message ) = @_;
	
	return unless ( $self->active_hand );
	if ( $message->from ne $self->active_hand->player ) {
		return 'Not your turn' . $self->generate_insult;
	}
	
	$self->game->hit( $self->active_hand );
	$self->hand_action();
}

sub double : GlobalRegEx('^bj? (d|double)$') {
	my ( $self, $message ) = @_;
	
	return unless ( $self->active_hand and $self->game->can_double( $self->active_hand ) );
	if ( $message->from ne $self->active_hand->player) {
		return 'Not your turn' . $self->generate_insult;
	}
	
	$self->game->double( $self->active_hand );
	return $self->hand_action();
}

sub stand : GlobalRegEx('^bj? (s|stand)$') {
	my ( $self, $message ) = @_;
	
	return unless ( $self->active_hand );
	if ( $message->from ne $self->active_hand->player) {
		return 'Not your turn' . $self->generate_insult;
	}
	
	$self->game->collect_hand( $self->active_hand );
	return $self->next_hand();
}

sub split : GlobalRegEx('^bj? (p|split)$') {
	my ( $self, $message ) = @_;
	
	return unless ( $self->active_hand and $self->game->can_split( $self->active_hand ) );
	if ( $message->from ne $self->active_hand->player) {
		return 'Not your turn' . $self->generate_insult;
	}
	
	my @hands = $self->game->split( $self->active_hand );
	$self->{'active_hand'} = $hands[0];
	splice( @{$self->hands}, 0, 0, $hands[1] );
	return $self->hand_action();
}

sub generate_insult {
	my ( $self, $is_plural ) = @_;

	return '.' unless ( $self->my_config and $self->my_config->{insult} );
	my $insult = $self->get_insult;
	if ($is_plural) {
		$insult .= ( $insult =~ /s$/ ? 'es' : 's' );
	} else {
		$insult = 'you ' . $insult;
	}

	return ', ' . $insult . '.';
}

__PACKAGE__->meta->make_immutable;

1;
