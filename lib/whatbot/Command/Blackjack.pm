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

has 'game'        => ( is => 'ro', isa => 'whatbot::Command::Blackjack::Game' );
has 'game_admin'  => ( is => 'rw', isa => 'Str' );
has 'bets'        => ( is => 'ro', isa => 'HashRef' );
has 'dealer_hand' => ( is => 'ro' );
has 'active_hand' => ( is => 'ro' );
has 'hands'       => ( is => 'ro', isa => 'ArrayRef' );
has 'suits'       => ( is => 'ro', isa => 'HashRef' );
has 'buyin'       => ( is => 'rw', isa => 'Int', default => 100 );
has 'last_insult' => ( is => 'rw', isa => 'Str', default => 'rand' );
has 'insults'     => ( is => 'ro', isa => 'ArrayRef', default => sub { [
    'retard',
    'wanker',
    'douchebag',
    'moron',
    'asshat'
] } );

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	
	$self->{'suits'} = {
        'hearts'    => "\x{2665}",
        'diamonds'  => "\x{2666}",
        'clubs'     => "\x{2663}",
        'spades'    => "\x{2660}"
    };
}

sub help : Command {
    my ( $self ) = @_;
    
    return [
        'Blackjack is a game of blackjack for whatbot. Hello, obvious. To ' .
        'begin, give the command "blackjack play". Blackjack will prompt ' .
        'you from there.',
        'As a quick reference, once you initiate a game, hit "bj me" to add ' .
        'yourself to a game, and the initater can do "bj start" to start ' .
        'the game. At any time, you can type "bj amounts" to see your money.'
    ];
}

sub play : Command {
    my ( $self, $message, $buy_in ) = @_;
    
    return 'Blackjack game already active.' if ( $self->game );
    
    $self->game_admin( $message->from );
    
    $buy_in = shift( @$buy_in );
    $self->{'game'} = new whatbot::Command::Blackjack::Game;
    $self->buyin($buy_in) if ($buy_in);
    
    return 'Blackjack time, buy in is $' . $self->buyin . '. Anyone who wants to play, type "bj me". ' . $message->from . ', type "bj start" when everyone is ready.';
}

sub add_player : GlobalRegEx('^bj me$') {
    my ( $self, $message ) = @_;
    
    return unless ( $self->game and $self->game->active_shoe != 1 );
    if ( $self->game->add_player( $message->from, $self->buyin ) ) {
        return 'Gotcha, ' . $message->from . '.';
    } else {
        return 'Already got you, ' . $message->from . ', you ' . $self->insult . '.';
    }
}

sub start : GlobalRegEx('^bj start$') {
    my ( $self, $message ) = @_;
    
    return unless ( $self->game and $message->from eq $self->game_admin );
    unless ( keys %{ $self->game->players } ) {
        return 'I need players before you can deal, you ' . $self->insult . '.';
    }
    
    $self->game->start({
        'buy_in' => $self->buyin
    });
    
    return $self->new_hand();
}

sub end_game : Command {
    my ( $self ) = @_;
    
    $self->{'game'} = undef;
    $self->{'game_admin'} = undef;
    $self->{'bets'} = undef;
    $self->{'dealer_hand'} = undef;
    $self->{'active_hand'} = undef;
    $self->{'hands'} = undef;
    $self->{'buyin'} = 100;
    $self->{'last_insult'} = 'rand';
    
    return 'Alright, fine, no more game for you.';
}

sub amounts : GlobalRegEx('^bj amounts') {
    my ( $self ) = @_;
    
    return 'Players: ' . join( ', ', map { $_ . ' with $' . ( $self->game->players->{$_} =~ /\./ ? sprintf( '%.02f', $self->game->players->{$_} ) : $self->game->players->{$_} ) } keys %{ $self->game->players } )
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
        push( @messages, 'No more players. Good work, ' . $self->insult . 's.' );
        $self->end_game();
        return \@messages;
    }
    push( @messages, 'New hand: Place your bets by typing "bj bet amount" where amount is your actual numeric bet. If you want to sit this out, hit bj bet 0. Then, eat my asshole.' );
    
    return \@messages;
}

sub bet : GlobalRegEx('^bj bet \$?(\d+(\.\d\d)?)$') {
    my ( $self, $message, $captures ) = @_;
    
    return unless ( $self->{'waiting_for_bets'} );
    
    my $bet = $captures->[0];
    return unless ( $bet and $bet > 0 );
    return 'You have not bought in, ' . $message->from . '.'
        unless ( $self->game->players->{ $message->from } );
    return 'You cannot bet $' . $bet . ', ' . $message->from . ', you only have $' . $self->game->players->{ $message->from } . '.' unless ( $self->game->players->{$message->from} >= $bet );
    
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
    $self->{'dealer_hand'} = shift( @{ $self->{'hands'} } );
    if ( $self->{'dealer_hand'}->first->{'value'} eq 'A' ) {
        # Insurance
    } elsif ( $self->{'dealer_hand'}->blackjack ) {
        my @messages;
        foreach my $hand ( @{$self->hands} ) {
            push( @messages, $self->show_hand($hand) );
        }
        push( @messages, $self->show_hand( $self->{'dealer_hand'} ) );
        push( @messages, 'Dealer has Blackjack. Thank you for all of your money, ' . $self->insult . ( keys %{ $self->bets } > 1 ? 's' : '' ) . '.' );
        return $self->new_hand( \@messages );
    }
    my $dealer_view = 'Dealer shows ' . $self->{'dealer_hand'}->first->{'value'} . $self->suits->{ $self->{'dealer_hand'}->first->{'suit'} } . '.';
    return $self->next_hand([ $dealer_view ]);
}

sub buyin : Command {
    my ( $self, $message ) = @_;
    
    return unless ( $self->game );
    if ( $self->game->add_player( $message->from, $self->buyin ) ) {
        return 'Gotcha, ' . $message->from . '.';
    } else {
        return 'Already got you, ' . $message->from . ', you ' . $self->insult . '.';
    }
}

sub next_hand {
    my ( $self, $messages ) = @_;
    
    my $hand = shift( @{ $self->hands } );
    
    # Check if last hand, if so, show dealer hand and cycle
    unless ($hand) {
        $messages = [] unless ($messages);
        $self->game->dealer_hand( $self->{'dealer_hand'} );
        my $output = 'Dealer: ' . $self->show_hand( $self->{'dealer_hand'} );
        if ( $self->{'dealer_hand'}->busted ) {
            $output .= ' Dealer busts.';
        } elsif ( $self->{'dealer_hand'}->score == 21 ) {
            $output .= ' Good luck.';
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
    my $output = $hand->player . ': ';
    $output .= $self->show_hand($hand);
    if ( $hand->blackjack ) {
        $output .= ' Congratulations, you got blackjack.';
        push( @messages, $output );
        $self->game->collect_hand($hand);
        return $self->next_hand(\@messages);
    } elsif ( $hand->busted ) {
        $output .= ' Good job, you busted, ' . $self->insult . '.';
        push( @messages, $output );
        $self->game->collect_hand($hand);
        return $self->next_hand(\@messages);
    } elsif ( $hand->score == 21 ) {
        $output .= ' That is 21, you are about done.';
        push( @messages, $output );
        $self->game->collect_hand($hand);
        return $self->next_hand(\@messages);
    } elsif ( $hand->last_draw ) {
        $output .= ' Enjoy your lots.';
        push( @messages, $output );
        $self->game->collect_hand($hand);
        return $self->next_hand(\@messages);
    } else {
        $output .= ' Start with "bj", then h/hit s/stand';
        $output .= ' d/double' if ( $self->game->can_double($hand) );
        $output .= ' p/split' if ( $self->game->can_split($hand) );
        $output .= '.';
        push( @messages, $output );
        return \@messages;
    }
    
}

sub show_hand {
    my ( $self, $hand ) = @_;
    
    my $output;
    foreach my $card ( @{ $hand->cards } ) {
        $output .= $card->{'value'} . $self->suits->{ $card->{'suit'} } . '  ';
    }
    $output .= '(' . $hand->score . ').';
    
    return $output;
}

sub hit : GlobalRegEx('^bj (h|hit)$') {
    my ( $self ) = @_;
    
    return unless ( $self->active_hand );
    
    $self->game->hit( $self->active_hand );
    $self->hand_action();
}

sub double : GlobalRegEx('^bj (d|double)$') {
    my ( $self ) = @_;
    
    return unless ( $self->active_hand and $self->game->can_double( $self->active_hand ) );
    
    $self->game->double( $self->active_hand );
    return $self->hand_action();
}

sub stand : GlobalRegEx('^bj (s|stand)$') {
    my ( $self ) = @_;
    
    return unless ( $self->active_hand );
    
    $self->game->collect_hand( $self->active_hand );
    return $self->next_hand();
}

sub split : GlobalRegEx('^bj (p|split)$') {
    my ( $self ) = @_;
    
    return unless ( $self->active_hand and $self->game->can_split( $self->active_hand ) );
    
    my @hands = $self->game->split( $self->active_hand );
    $self->{'active_hand'} = $hands[0];
    splice( @{$self->hands}, 1, 0, $hands[1] );
    return $self->hand_action();
}

sub insult {
    my ( $self ) = @_;
    
    my $insult = $self->last_insult;
    while ( $insult eq $self->last_insult ) {
        $insult = $self->insults->[ int( rand( scalar( @{$self->insults} ) ) ) ];
    }
    $self->last_insult($insult);
    
    return $insult;
}

1;