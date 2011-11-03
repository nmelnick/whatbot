package whatbot::Command::Blackjack::Card;
use Moose;
# use String::IRC;
use namespace::autoclean;

has 'value'     => ( is => 'rw' );
has 'color'     => ( is => 'rw', isa => 'Str' );
has 'unicode'   => ( is => 'rw', isa => 'Str' );
has 'suit'      => ( is => 'rw', isa => 'Str', trigger => sub {
    my $self = shift;
    $self->color( $self->suits->{ $self->suit }->{'color'} );
    $self->unicode( $self->suits->{ $self->suit }->{'uni'} );
} );
has 'suits'     => ( is => 'ro', isa => 'HashRef', default => sub { {
    'diamonds'  => {
        'color' => 'red',
        'uni'   => "\x{2666}"
    },
    'hearts'    => {
        'color' => 'red',
        'uni'   => "\x{2665}"
    },
    'clubs'     => {
        'color' => 'black',
        'uni'   => "\x{2663}"
    },
    'spades'    => {
        'color' => 'black',
        'uni'   => "\x{2660}"
    },
} } );

sub ircize {
    my ( $self ) = @_;
    
    my $string = $self->value . $self->unicode;
    # I think this sucks.
    # if ( $self->color eq 'red' ) {
    #     my $irc = String::IRC->new( ' ' . $string . ' ' );
    #     $irc->red();
    #     $string = $irc->stringify();
    # }
    
    return $string;
}

__PACKAGE__->meta->make_immutable;

1;