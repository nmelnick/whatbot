###########################################################################
# whatbot/IO.pm
###########################################################################
# Base class for whatbot IO classes
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::IO;
use Moose;
extends 'whatbot::Component';

use whatbot::Message;

has 'my_config' => ( is => 'rw', isa => 'HashRef' );
has 'name'      => ( is => 'rw', isa => 'Str' );
has 'me'        => ( is => 'rw', isa => 'Str' );

sub BUILD {
	my ( $self ) = @_;
	
	unless ( defined $self->my_config ) {
		die 'No configuration found for ' . ref($self);
	}
}

sub notify {
	my ( $self, $message ) = @_;
	
	$self->log->write( '(' . $self->name . ') ' . $message )
	    unless ( defined $self->my_config->{'silent'} );
}

sub connect {
	my ( $self ) = @_;
	
}

sub disconnect {
	my ( $self ) = @_;
	
}

sub event_user_enter {
	my ( $self ) = @_;
	
}

sub event_user_leave {
	my ( $self ) = @_;
	
}

sub event_message_public {
	my ( $self, $from, $content ) = @_;
	
	my $message;
	if ( ref($content) eq 'whatbot::Message' ) {
		$message = $content;
		$self->notify('[PUB] <' . $from . '> ' . $content->content);
		
	} else {
		$self->notify( '[PUB] <' . $from . '> ' . $content );
		$message = new whatbot::Message(
			'from'			    => $from,
			'to'				=> 'public',
			'content'			=> $content,
			'timestamp'		    => time,
			'me'				=> $self->me,
			'base_component'	=> $self->parent->base_component,
			'origin'			=> $self,
		);
	}
	if ( $from eq $self->me ) {
	    $self->parent->last_message($message);
    } else {
	    $self->parse_response( $self->controller->handle($message) );
    }
}

sub event_message_private {
	my ( $self, $from, $content ) = @_;
	
	$self->notify( '[PRI] <' . $from . '> ' . $content );
	unless ( $from eq $self->me ) {
    	my $message = new whatbot::Message(
    		'from'			    => $from,
    		'to'				=> $self->me,
    		'content'			=> $content,
    		'timestamp'		    => time,
    		'is_private'		=> 1,
    		'me'				=> $self->me,
    		'base_component'	=> $self->parent->base_component,
			'origin'			=> $self,
    	);
    	$self->parse_response( $self->controller->handle($message) );
    }
	
}

sub event_action {
	my ( $self, $from, $content ) = @_;
	
	$self->notify( '[ACT] ' . $from . ' ' . $content );
}

sub send_message {
	my ( $self, $message ) = @_;
	
}

sub parse_response {
	my ( $self, $messages ) = @_;
	
	return undef unless ( defined $messages );
	foreach my $message ( @{$messages} ) {
	    $self->send_message($message);
	}
}

1;