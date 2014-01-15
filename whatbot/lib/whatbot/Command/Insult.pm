###########################################################################
# whatbot/Command/Insult.pm
###########################################################################
# Provides insults to other commands, insults on command.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Insult;
use Moose;
BEGIN { extends 'whatbot::Command' }
use namespace::autoclean;

has 'last_insult' => ( is => 'rw', isa => 'Str', default => 'rand' );
has 'insults'     => ( is => 'ro', isa => 'ArrayRef', default => sub { [
    'retard',
    'wanker',
    'douchebag',
    'moron',
    'asshat',
    'jackass'
] } );

sub register {
	my ($self) = @_;
	
	$self->command_priority('Primary');
	$self->require_direct(0);

	if ( $self->my_config and $self->my_config->{insults} ) {
		push( @{ $self->insults }, split( /, */, $self->my_config->{insults} ) );
	}
}

sub get_insult {
    my ( $self ) = @_;
    
    my $insult = $self->last_insult;
    while ( $insult eq $self->last_insult ) {
        $insult = $self->insults->[ int( rand( scalar( @{$self->insults} ) ) ) ];
    }

    return $self->last_insult($insult);
}

sub parse_message : CommandRegEx('(\w+)') {
    my ( $self, $message, $captures ) = @_;
    
    return unless ( $captures and @$captures );
    my $insult = $self->get_insult;
	return $captures->[0] . ', you are a' . ( $insult =~ /^[aeiou]/ ? 'n' : '' ) . ' ' . $insult . '.';
}

__PACKAGE__->meta->make_immutable;

1;
