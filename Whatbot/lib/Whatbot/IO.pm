###########################################################################
# Whatbot/IO.pm
###########################################################################
# Base class for whatbot IO classes
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::IO - Base class for Whatbot IO modules

=head1 SYNOPSIS

 use Moops;
 use Whatbot::Command; # Import subroutine attributes
 class Whatbot::IO::Example extends Whatbot::IO {

   method BUILD (...) {
     $self->name('Example');
     $self->me( $self->my_config->{'nickname'} );
   }

   method connect() {}

   method disconnect() {}

   method send_message($message) {}
 }

=head1 DESCRIPTION

Whatbot::IO is a base class, meant to be subclassed by an IO provider or engine
to connect to an external chat/messaging service. It provides a skeleton
structure to create a a provider, and methods to handle communication in and out
of Whatbot.

Keep in mind that if you're looking for functionality that you'd expect in your
IO provider, and not seeing it here, double check L<Whatbot::Component>.

Some terminology used:

=over 4

=item context

This is the context in which this bot is chatting on this service. In IRC, this
would be known as the 'channel', where other services may call it a 'room'.

=item topic

A description for a context, taken from the IRC concept of a topic.

=item nick

A username or nickname of an individual within the context, taken from IRC.

=back

=head1 PUBLIC ACCESSORS

=over 4

=item my_config

The portion of the user's configuration file devoted to this IO module.

=item name

The name of this IO module, used in logging or looking up a provider to send a
message through.

=item me

The name or nickname of this instance of Whatbot in this IO module.

=item ignore

A list of users or tags to ignore processing of.

=back

=cut

class Whatbot::IO extends Whatbot::Component {
	use Whatbot::Message;

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

=head1 IMPLEMENTATION METHODS

These methods are required to be implemented to provide a fully functional IO
module for Whatbot.

=over 4

=item connect()

Override this method. This method is called when Whatbot is connecting to this
module, whether on first load, or after a disconnection.

=cut

	method connect {
	}

=item disconnect()

Optionally override this method. This method is called when Whatbot is
attempting to disconnect from this module, generally when Whatbot is exiting.

=cut

	method disconnect {
	}

=item deliver_message($message)

Optionally override this method. This method, given a Whatbot::Message, will
send the message out through this service.

=cut

	method deliver_message( $message ) {
		$self->log->error( ref($self) . ' does not know how to deliver_message' );
	}

=item format_user($user)

Optionally override this method. This method is given a username as tagged by
a command or within Whatbot, and the module may optionally reformat it before
the message is provided to deliver_message. Services that employ @mentions may
use this to convert a bare username to a mention or vice versa. Default
implementation leaves the username as is.

=cut

	method format_user($user) {
		return $user;
	}

=back

=head1 PUBLIC METHODS

=over 4

=item send_message($message)

Send a message through this provider.

=cut

	method send_message($message) {
		my $content = $message->text;
		if ( $content =~ /\{!user=/ and $content !~ /\{!user=.*?\}/ ) {
			die 'Unclosed user tag in ' . $message->text;
		}
		$content =~ s/\{!user=(.*?)\}/$self->format_user($1)/ge;
		my $new_message = $message->clone();
		$new_message->text($content);
		return $self->deliver_message($new_message);
	}

=item notify($context, $message)

Write a message to the log with clear indication that this module is the sender
of that message.

=cut

	method notify( Str $context, Str $message ) {
		$self->log->write( sprintf( '(%s) [%s] %s', $self->name, $context, $message ) )
			unless ( defined $self->my_config->{'silent'} );
	}

=item event_user_enter($context, $nick)

Send a Whatbot event that a user has entered the context.

=cut

	method event_user_enter( $context?, $nick? ) {
		$self->notify( $context, '** ' . $nick . ' has entered' );
		$self->parse_response(
			$self->controller->handle_event(
				join( ':', $self->name, $context ),
				'enter',
				{
					'nick' => $nick
				},
				$self->me
			)
		);
	}

=item event_user_change($context, $old_nick, $new_nick)

Send a Whatbot event that a user has changed their name.

=cut

	method event_user_change( $context?, $old_nick?, $new_nick? ) {
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

=item event_user_leave($context, $nick)

Send a Whatbot event that a user has left the context.

=cut

	method event_user_leave( $context?, $nick?, $message? ) {
		$self->notify( $context, '** ' . $nick . ' has left ' );
		$self->parse_response(
			$self->controller->handle_event(
				join( ':', $self->name, $context ),
				'leave',
				{
					'nick' => $nick
				},
				$self->me
			)
		);
	}

=item event_ping($source)

Send a Whatbot event that someone has sent a ping-like request to Whatbot.

=cut

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

=item event_topic($context, $topic, $who)

Send a Whatbot event that the topic of this context has changed.

=cut

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

=item event_message($message)

Send a Whatbot event that a message has been received. This will generally
invoke one or more commands. The $message variable must be a Whatbot::Message.

=cut

	method event_message( Whatbot::Message $message ) {
		$self->notify( $message->to, '<' . $message->from . '> ' . $message->text );
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

=item event_action($to, $from, $content)

Send a Whatbot event that an action has been received. An action is a message
that a user is doing something. In IRC, this is triggered when someone sends a
/me.

=cut

	method event_action( Str $to, Str $from, Str $content ) {
		$self->notify( $to, '[ACT] ' . $from . ' ' . $content );
	}

=item get_new_message(\%params)

Get a new instance of a Whatbot::Message with a prefilled 'me', and then given
$params, as one would pass into Whatbot::Message->new().

=cut

	method get_new_message( HashRef $params ) {
		return Whatbot::Message->new({
			'me' => $self->me,
			%$params
		})
	}

	method parse_response( $messages ) {
		$messages = [$messages] unless ( ref($messages) and ref($messages) eq 'ARRAY' );
		foreach my $message ( @{$messages} ) {
			$self->send_message($message);
		}
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

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
