###########################################################################
# whatbot/IO.pm
###########################################################################
# Base class for whatbot IO classes
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::IO extends whatbot::Component {
    use whatbot::Message;

    has 'my_config' => ( is => 'rw', isa => 'HashRef' );
    has 'name'      => ( is => 'rw', isa => 'Str' );
    has 'me'        => ( is => 'rw', isa => 'Str' );

    method BUILD ($) {
    	unless ( defined $self->my_config ) {
    		die 'No configuration found for ' . ref($self);
    	}
    }

    method notify ( Str $message ) {
    	$self->log->write( '(' . $self->name . ') ' . $message )
    	    unless ( defined $self->my_config->{'silent'} );
    }

    method connect {
    }

    method disconnect {
    }

    method event_user_enter ( $from? ) {
    	$self->notify( '**' . $from . ' has entered' );
	    $self->parse_response( $self->controller->handle_event( 'enter', $from ) );
    }

    method event_user_leave ( $from? ) {
    	$self->notify( '**' . $from . ' has left' );
	    $self->parse_response( $self->controller->handle_event( 'leave', $from ) );
    }

    method event_message_public ( Str $from, $content, $optional? ) {
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

    method event_message_private ( Str $from, Str $content ) {
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

    method event_action ( Str $from, Str $content ) {
    	$self->notify( '[ACT] ' . $from . ' ' . $content );
    }

    method send_message ( $message ) {
    }

    method parse_response ( $messages ) {
    	return unless ( defined $messages );
    	foreach my $message ( @{$messages} ) {
    	    $self->send_message($message);
    	}
    }
}

1;
