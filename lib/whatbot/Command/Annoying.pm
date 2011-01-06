###########################################################################
# whatbot/Command/Annoying.pm
###########################################################################
# makes whatbot annoying
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Annoying;
use Moose;
BEGIN { extends 'whatbot::Command'; }

use Acme::LOLCAT;

has be_annoying => ( is => 'rw', isa => 'Bool' );

sub register {
	my ($self) = @_;
	
	$self->command_priority('Last');
	$self->require_direct(0);
}

sub toggle : GlobalRegEx('^(don.t )?be annoying[\.\!]?$') {
    my ( $self, $message, $captures ) = @_;
	
	$self->be_annoying( $self->be_annoying ? 0 : 1 );
	return 'OK, I am ' . ( $self->be_annoying ? '' : 'no longer as ' ) . 'annoying.';
}

sub respond : GlobalRegEx('.') {
	my ( $self, $message ) = @_;
	
	return unless ( $self->be_annoying and not $message->content =~ /^(don.t )?be annoying[\.\!]?$/ );
	return $self->annoying( $message->content );
}

sub annoying {
	my ( $self, $content ) = @_;
	
	return translate($content);
}

1;
