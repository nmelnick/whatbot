###########################################################################
# whatbot/Message.pm
###########################################################################
# whatbot message object, created for each incoming and outgoing message.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Message;
use Moose;
extends "whatbot::Component";

has 'from'          => ( is => 'rw', isa => 'Str', required => 1 );
has 'to'            => ( is => 'rw', isa => 'Str', required => 1 );
has 'content'       => ( is => 'rw', isa => 'Str', required => 1 );
has 'timestamp'     => ( is => 'rw', isa => 'Int', default => time );
has 'is_private'    => ( is => 'rw', isa => 'Int', default => 0 );
has 'is_direct'     => ( is => 'rw', isa => 'Int', default => 0 );
has 'me'            => ( is => 'rw', isa => 'Str' );

sub BUILD {
	my ( $self ) = @_;
	
	my $me = $self->me;
	
	if ( defined $me ) {
		if ( $self->content =~ /, ?$me[\?\!\. ]*?$/i ) {
			my $content = $self->content;
			$content =~ s/, ?$me[\?\!\. ]*?$//;
			$self->content($content);
			$self->is_direct(1);
			
		} elsif ( $self->content =~ /^$me[\:\,\- ]+/i ) {
			my $content = $self->content;
			$content =~ s/^$me[\:\,\- ]+//i;
			$self->content($content);
			$self->is_direct(1);
			
		} elsif ( $self->content =~ /^$me \-+ /i ) {
			my $content = $self->content;
			$content =~ s/^$me \-+ //i;
			$self->content($content);
			$self->is_direct(1);
			
		}
	}
}

1;