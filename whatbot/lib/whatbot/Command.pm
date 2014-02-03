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

=head1 PUBLIC ACCESSORS

=over 4

=cut

class whatbot::Command extends whatbot::Component {
    use whatbot::Types qw( HTTPRequest );

    has 'name'             => ( is => 'rw', isa => 'Str' );

=item command_priority

Determines at what point in the processing order this command will fire. Valid
entries are 'Primary', 'Core', 'Extension', and defaults to Extension. Primary
are first runners, Core are components considered essential, and Extension is
parsed in order after those components.

=cut

    has 'command_priority' => ( is => 'rw', isa => 'Str', default => 'Extension' );

=item require_direct

Forces the module to only respond if the name of the bot is used in the message.

=cut

    has 'require_direct'   => ( is => 'rw', isa => 'Int', default => 0 );

=item my_config

Contains the configuration for this module from the whatbot config file, if any.

=cut
    has 'my_config'        => ( is => 'ro', isa => 'Maybe[HashRef]' );

=item timer

Provides access to whatbot::Timer functionality.

=cut

    has 'timer'            => ( is => 'rw', lazy_build => 1 );

    sub _build_timer {
        return $_[0]->ios->{Timer};
    }


=back

=head1 PUBLIC METHODS

=over 4

=cut

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