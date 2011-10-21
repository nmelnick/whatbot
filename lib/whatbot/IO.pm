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

    method notify ( Str $context, Str $message ) {
    	$self->log->write( sprintf( '(%s) [%s] %s', $self->name, $context, $message ) )
    	    unless ( defined $self->my_config->{'silent'} );
    }

    method connect {
    }

    method disconnect {
    }

    method event_user_enter ( $context?, $from? ) {
    	$self->notify( $context, '** ' . $from . ' has entered' );
	    $self->parse_response( $self->controller->handle_event( 'enter', $from, $self->me ) );
    }

    method event_user_leave ( $context?, $from? ) {
    	$self->notify( $context, '**' . $from . ' has left ' );
	    $self->parse_response( $self->controller->handle_event( 'leave', $from, $self->me ) );
    }

    method event_message ( whatbot::Message $message ) {
    	$self->notify( $message->to, '<' . $message->from . '> ' . $message->content );
        $message->me( $self->me );
        $message->origin( join( ':', $self->name, ( $message->is_private ? $message->from : $message->to ) ) );
    	if ( $message->from eq $self->me ) {
    	    $self->parent->last_message($message);
        } else {
    	    $self->parse_response( $self->controller->handle_message($message) );
        }
    }

    method event_action ( Str $to, Str $from, Str $content ) {
    	$self->notify( $to, '[ACT] ' . $from . ' ' . $content );
    }

    method send_message ( $message ) {
    }

    method parse_response ( $messages ) {
        $messages = [$messages] unless ( ref($messages) and ref($messages) eq 'ARRAY' );
    	foreach my $message ( @{$messages} ) {
    	    $self->send_message($message);
    	}
    }

    method get_new_message( HashRef $params ) {
        return whatbot::Message->new({
            'me' => $self->me,
            %$params
        })
    }
}

1;
