package whatbot::Command::Blackjack::Hand;
use Moose;

has 'player'    => ( is => 'rw', isa => 'Str' );
has 'cards'     => ( is => 'ro', isa => 'ArrayRef', default => sub { [] } );
has 'last_draw' => ( is => 'rw', isa => 'Int', default => 0 );

sub clone {
    my ( $self ) = @_;
    
    return new whatbot::Command::Blackjack::Hand(
        'player'    => $self->player
    );
}
sub fingerprint {
    my ( $self ) = @_;
    
    return join( '',
        $self->player,
        $self->first->{'value'},
        $self->first->{'suit'},
        $self->second->{'value'},
        $self->second->{'suit'}
    );
}
sub first {
    my ( $self ) = @_;
    
    return $self->cards->[0];
}

sub second {
    my ( $self ) = @_;
    
    return $self->cards->[1];
}

sub give {
    my ( $self, $card ) = @_;
    
    push( @{ $self->cards }, $card );
}

sub busted {
    my ( $self ) = @_;
    
    return 1 if ( $self->score > 21 );
    return;
}

sub blackjack {
    my ( $self ) = @_;
    
    return 1 if ( ( $self->score eq 21 or ( $self->score eq 11 and $self->has_ace ) )and $self->card_count == 2 );
    return;
}

sub card_count {
    my ( $self ) = @_;
    
    return scalar( @{ $self->cards } );
}

sub has_ace {
    my ( $self ) = @_;
    
    foreach my $card ( @{ $self->cards } ) {
        return 1 if ( $card->{'value'} eq 'A' );
    }
    return;
}

sub can_double {
    my ( $self ) = @_;
    
    return 1 if ( $self->card_count == 2 and $self->score > 8 and $self->score < 12 );
    return;
}

sub can_split {
    my ( $self ) = @_;
    
    return 1 if ( $self->card_count == 2 and $self->first->{'value'} eq $self->second->{'value'} );
    return;
}

sub score {
    my ( $self ) = @_;
    
    my $score = 0;
    foreach my $card ( @{ $self->cards } ) {
        if ( $card->{'value'} =~ /[KQJ]/ ) {
            $score += 10;
        } elsif ( $card->{'value'} eq 'A' ) {
            $score += 1;
        } else {
            $score += $card->{'value'}
        }
    }
    if ( $self->card_count == 2 and $self->has_ace and $score == 11 ) {
        return 21;
    }
    
    return $score;
}

1;