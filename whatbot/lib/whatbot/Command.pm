###########################################################################
# whatbot/Command.pm
###########################################################################
#
# Base class for whatbot commands
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Command - Base class for whatbot commands

=head1 SYNOPSIS

 package whatbot::Command::Example;
 use Moose;
 BEGIN { extends 'whatbot::Command' }
 
 sub register {
     my ($self) = @_;
     
     $self->require_direct(0);
 }

=head1 DESCRIPTION

whatbot::Command is a base class, meant to be subclassed by any additional
whatbot command or extension. It provides a skeleton structure to create a
new command, parses command attributes, and gives the warnings necessary when
a command is not implemented properly.

To create a new command, subclass this module using Moose's 'extends' pragma,
and override the given methods with your own. Set attributes to your methods
to hook into events.

=head1 RETURN VALUES

Each subroutine called by the Controller can return either a string or a 
whatbot::Message.

=head1 SUBROUTINE ATTRIBUTES

A Command can respond to different types of messages, triggers, and events, and
those are communicated via subroutine attributes. These attributes can be 
combined for any individual method, or you can structure your code to have
different entry points for each event. The available attributes are:

=over 4

=item Command

Command is the most basic event type. The given method would fire when a message
comes in with "<command-name> <method-name>". For example, for the command
"Seen", and the method name "test", then it would fire if someone stated "seen
test" in whatever context whatbot is listening.

=item CommandRegEx('$regex')

CommandRegEx is similar to Command, where it listens after the command name,
except it will look for a match to the given regex instead of the method name.
To respond to "seen test", you would provide CommandRegEx('test').

=item GlobalRegEx('$regex')

GlobalRegEx will fire if the given regex is found on any input, whether the
command name is involved or not. This is useful for parsing any content in a
message, or looking for a triggering keyword.

=item Monitor

Monitor will fire on any incoming, visible message.

=item StopAfter

Force whatbot to stop processing commands after this method returns.

=item Event('$event')

Event will fire on the given incoming event. To specify multiple events to
respond to, multiple Event attributes must be provided. An Event attribute
does result in a change to the method signature, as it will provide $self,
$target, which is the context that the event was fired from, and $event_info,
which is a hashref containing different data depending on the event. Events are
provided by IO modules, so you will want to check those for additional event
types. In general, the possible events are:

=over 4

=item enter : $event_info contains 'nick'

=item user_change : $event_info contains 'nick', 'old_nick'

=item leave : $event_info contains 'nick'

=item ping : $event_info contains 'source'

=item topic : $event_info contains 'nick', 'topic'

=back

=back

=head1 PUBLIC ACCESSORS

=over 4

=item command_priority

Determines at what point in the processing order this command will fire. Valid
entries are 'Primary', 'Core', 'Extension', and defaults to Extension. Primary
are first runners, Core are components considered essential, and Extension is
parsed in order after those components.

=item require_direct

Forces the module to only respond if the name of the bot is used in the message.

=item my_config

Contains the configuration for this module from the whatbot config file, if any.

=item timer

Provides access to whatbot::Timer functionality.

=back

=head1 PUBLIC METHODS

=over 4

=cut

class whatbot::Command extends whatbot::Component {
    use whatbot::Types qw( HTTPRequest );

    has 'name'             => ( is => 'rw', isa => 'Str' );
    has 'require_direct'   => ( is => 'rw', isa => 'Int', default => 0 );
    has 'my_config'        => ( is => 'ro', isa => 'Maybe[HashRef]' );
    has 'timer'            => ( is => 'rw', lazy_build => 1 );

    sub _build_timer {
        return $_[0]->ios->{Timer};
    }

    our $_attribute_cache = {};

    sub MODIFY_CODE_ATTRIBUTES {
        my ( $class, $code, @attrs ) = @_;
    
        $_attribute_cache = { %{ $_attribute_cache }, $code => [@attrs] };
        return ();
    }

    sub FETCH_CODE_ATTRIBUTES {
        $_attribute_cache->{ $_[1] } || ();
    }

    method BUILD(...) {
        $self->register();
    }

=item register()

Called after class instantiation to set properties and instantiate any
persistent objects required by the Command. This would be the equivalent of
new() or BUILD() for your command.

=cut

    method register() {
        $self->log->write(ref($self) . ' works without a register method, but it is recommended to make one.');
    }

=item help()

Returned when a user asks for help on a command. You can also add a : Command
attribute so someone may ask your command for help directly.

=cut

    method help() {
        return 'Help is not available for this module.';
    }

=item web( $path, \&callback )

Set up a web endpoint, used within the register() function. The first parameter
is a path to respond to after the hostname and port of the request. Note that
the first path registered wins, so choose your paths carefully. The second
parameter is a callback when a request is received. Three parameters are sent to
the callback: $self, which is your command's instance, $httpd, which is an
L<AnyEvent::HTTPD> object, and $req, which is a L<AnyEvent::HTTPD::Request>
object.

=cut

    method web( $path, $callback ) {
        return unless ( $self->ios->{Web} );
        return $self->ios->{Web}->add_dispatch( $self, $path, $callback );
    }

=item web_url()

Returns the URL that the web server is currently responding to.

=cut

    method web_url() {
        return unless ( $self->ios->{Web} );
        return sprintf( '%s:%d', $self->ios->{Web}->my_config->{url}, $self->ios->{Web}->my_config->{port} );
    }

    before log() {
        $self->base_component->log->name( $self->name );
    }

}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
