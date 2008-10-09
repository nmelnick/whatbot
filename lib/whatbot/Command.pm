###########################################################################
# whatbot/Command.pm
###########################################################################
#
# Base class for whatbot commands
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command;
use Moose;
extends 'whatbot::Component';
no warnings 'redefine';

use Attribute::Handlers;
use Data::Dumper 'Dumper';

sub MODIFY_CODE_ATTRIBUTES {
    my ( $class, $code, @attrs ) = @_;
    warn Data::Dumper::Dumper(@_);
    return ();
}

sub FETCH_CODE_ATTRIBUTES {
    my ( $class, $code, @attrs ) = @_;
    warn Data::Dumper::Dumper(@_);
    return ();
}

# commandPriority determines at what point in the processing order this
# parseMessage will fire.
# Valid entries are 'Primary', 'Core', 'Hook', and 'Extension'.
has 'commandPriority' => (
	is	=> 'rw',
	isa	=> 'Str',
	default => 'Extension'
);
# listenFor can contain a string or a compiled regex with the match
# string/pattern of the incoming message object. If listenFor is
# blank, all messages will be parsed by this module.
has 'listenFor' => (
	is	=> 'rw',
	isa	=> 'Any'
);
# requireDirect forces the module to only respond if the name of the
# bot is used in the message as a direction.
has 'requireDirect' => (
	is	=> 'rw',
	isa	=> 'Int',
	default => 0
);
# passThrough, if set to 1, will pass through for further Command
# processing, even if the command outputs text to IO. Commands will
# automatically pass through if undef or an empty string is passed.
has 'passThrough' => (
	is	=> 'rw',
	isa	=> 'Int',
	default	=> 0
);
# myConfig contains the configuration for this module from the
# whatbot config file, if any.
has 'myConfig' => (
	is	=> 'ro',
	isa	=> 'HashRef'
);

sub BUILD {
	my ($self) = @_;
	
	$self->register();
}

# register is called after class instantiation to set properties and
# instantiate any persistent objects required by the Command.
sub register {
	my ($self) = @_;
}

# parseMessage is called with the message object for parsing.
sub parseMessage {
	my ($self, $messageRef, $matchIndex, @matches) = @_;
	
	$self->log->write(ref($self) . " is useless without a parseMessage method, but received a message anyway.");
	return undef;
}

# help is returned when a user asks for help on a command.
sub help {
    my ($self) = @_;
    
    return 'Help is not available.';
}

1;