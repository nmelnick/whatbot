###########################################################################
# whatbot/IO.pm
###########################################################################
# Base class for whatbot IO classes
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::IO extends whatbot::Component {
	use whatbot::Message;

	has 'my_config' => ( is => 'rw', isa => 'HashRef' );
	has 'name'      => ( is => 'rw', isa => 'Str' );
	has 'me'        => ( is => 'rw', isa => 'Str', default => '' );
	has 'ignore'    => ( is => 'rw', isa => 'Maybe[ArrayRef]', lazy_build => 1 );

	method _build_ignore(...) {
		if (
			$self->my_config->{ignore}
			and ref( $self->my_config->{ignore} )
			and ref( $self->my_config->{ignore} ) eq 'ARRAY'
		) {
			return $self->my_config->{ignore};
		}
		return;
	}

	method BUILD(...) {
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
		$self->parse_response(
			$self->controller->handle_event(
				join( ':', $self->name, $context ),
				'enter',
				{
					'nick' => $from
				},
				$self->me
			)
		);
	}

	method event_user_change ( $context?, $old_nick?, $new_nick? ) {
		$self->notify( $context, '** ' . $old_nick . ' is now ' . $new_nick );
		$self->parse_response(
			$self->controller->handle_event(
				join( ':', $self->name, $context ),
				'user_change',
				{
					'nick'     => $new_nick,
					'old_nick' => $old_nick,
				},
				$self->me
			)
		);
	}

	method event_user_leave ( $context?, $from?, $message? ) {
		$self->notify( $context, '** ' . $from . ' has left ' );
		$self->parse_response(
			$self->controller->handle_event(
				join( ':', $self->name, $context ),
				'leave',
				{
					'nick' => $from
				},
				$self->me
			)
		);
	}

	method event_ping ( $source? ) {
		$self->parse_response(
			$self->controller->handle_event(
				join( ':', $self->name, '' ),
				'ping',
				{
					'source' => $source
				},
				$self->me
			)
		);
	}

	method event_topic ( $context, $topic, $who ) {
		$self->parse_response(
			$self->controller->handle_event(
				join( ':', $self->name, $context ),
				'topic',
				{
					'nick'  => $who,
					'topic' => $topic,
				},
				$self->me
			)
		);
	}

	method event_message ( whatbot::Message $message ) {
		$self->notify( $message->to, '<' . $message->from . '> ' . $message->content );
		$message->me( $self->me );
		$message->origin( join( ':', $self->name, ( $message->is_private ? $message->from : $message->to ) ) );
		if ( $message->from eq $self->me ) {
			$self->parent->last_message($message);
		} else {
			unless ( $self->_is_ignored_user( $message->from ) ) {
				$self->parse_response( $self->controller->handle_message($message) );
			}
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

	method _is_ignored_user( Str $user ) {
		if ( $self->ignore ) {
			foreach my $ignore_user ( @{ $self->ignore } ) {
				return 1 if ( $user eq $ignore_user );
			}
		}
		return;
	}
}

1;
