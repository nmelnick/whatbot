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

class whatbot::Command extends whatbot::Component {
    use whatbot::Types qw( HTTPRequest );

    has 'command_priority' => ( is => 'rw', isa => 'Str', default => 'Extension' );
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

    method BUILD ($) {
        $self->register();
    }

    method register {
        $self->log->write(ref($self) . ' works without a register method, but it is recommended to make one.');
    }

    method help {
        return 'Help is not available for this module.';
    }

    method async ( $req, $callback ) {
        return $self->ios->{Async}->enqueue( $self, $req, $callback );
    }

}

1;

=pod

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
whatbot::Message. Anywhere in an outgoing message where the word '!who' is
found will be replaced by the name of the sender of the triggering message.

=head1 PUBLIC ACCESSORS

=over 4

=item command_priority

Determines at what point in the processing order this command will fire.
Valid entries are 'Primary', 'Core', 'Extension', and defaults to
Extension. Primary are first runners, Core are components considered
essential, and Extension is parsed in order after those components. 

=item require_direct

Forces the module to only respond if the name of the bot is used in the message.

=item my_config

Contains the configuration for this module from the whatbot config file, if any.

=item timer

Provides access to whatbot::Timer functionality.

=back

=head1 PUBLIC METHODS

=over 4

=item register()

Called after class instantiation to set properties and instantiate any
persistent objects required by the Command.

=item help()

Returned when a user asks for help on a command.

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Command

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut