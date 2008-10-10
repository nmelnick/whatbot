###########################################################################
# whatbot/IO/IRC.pm
###########################################################################
#
# whatbot IRC connector
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::IO::IRC;
use Moose;
extends 'whatbot::IO';

use Net::IRC;

has 'handle' => (
	is	=> 'rw'
);
has 'ircHandle' => (
	is	=> 'ro',
	isa	=> 'Net::IRC::Connection'
);
has 'forceDisconnect' => (
	is	=> 'rw',
	isa	=> 'Int'
);

sub BUILD {
	my ($self) = @_;
	
	my $name = "IRC_" . $self->my_config->{host} . "_" . $self->my_config->{channel}->{name};
	$name =~ s/ /_/g;
	$self->name($name);
	$self->me($self->my_config->{nick});
}

sub connect {
	my ($self) = @_;
	
	my $handle = new Net::IRC;
	$self->handle($handle);
	$self->log->write(
		"Connecting to " . 
		$self->my_config->{host} . ":" . $self->my_config->{port} . 
		".");
	
	# Net::IRC Connection Parameters
	$self->{ircHandle} = $self->handle->newconn(
		Server		=> $self->my_config->{host},
		Port		=> $self->my_config->{port},
		Username	=> $self->my_config->{username},
		Ircname		=> $self->my_config->{realname},
		Password	=> $self->my_config->{hostpassword},
		Nick		=> $self->my_config->{nick},
	);
	
	# Everything's event based, so we set up all the callbacks
	$self->ircHandle->add_handler('msg',		\&cbPrivateMessage);
	$self->ircHandle->add_handler('public',		\&cbMessage);
	$self->ircHandle->add_handler('caction',	\&cbAction);
	$self->ircHandle->add_handler('join',		\&cbJoin);
	$self->ircHandle->add_handler('part',		\&cbPart);
	$self->ircHandle->add_handler('cping',		\&cbPing);
	$self->ircHandle->add_handler('topic',		\&cbTopic);
	$self->ircHandle->add_handler('notopic',	\&cbTopic);
	
	$self->ircHandle->add_global_handler(376, 			\&cbConnect);
	$self->ircHandle->add_global_handler('disconnect', \&cbDisconnect);
	$self->ircHandle->add_global_handler(353, 			\&cbNames);
	$self->ircHandle->add_global_handler(433, 			\&cbNickTaken);
	
	# I can't figure out how else to use this damn module in an OO way,
	# so I just do hax. They say if it takes a lot of work, you aren't
	# doing it right. Fine. Tell me how to fix this, then, and don't
	# say POE::Component::IRC. infobot hasn't released a new version
	# because they're moving to POE. Rapid development my ass.
	$self->ircHandle->{_whatbot} = $self;
	
	# Now we start one event loop so we can actually connect.
	$self->handle->do_one_loop();
	
}

sub disconnect {
	my ($self) = @_;
	
	$self->forceDisconnect(1);
	$self->ircHandle->quit($self->my_config->{quitmessage});
}

sub event_loop {
	my ($self) = @_;
	
	$self->handle->do_one_loop();
}

# Send a message
sub send_message {
	my ($self, $messageObj) = @_;
	
	# We're going to try and be smart.
	my $charactersPerLine = "450";
	if (defined($self->my_config->{charactersperline}) 
	    and ref($self->my_config->{charactersperline}) ne 'HASH') {
		$charactersPerLine = $self->my_config->{charactersperline};
	}
	my @lines;
	my @messageWords = split(/\s/, $messageObj->content);
	
	# If any of the words are over our maxlength, then let Net::IRC split it.
	# Otherwise, it's probably actual conversation, so we should split words.
	my $line = "";
	foreach my $word (@messageWords) {
		if (length($word) > $charactersPerLine) {
			my $msg = $messageObj->content;
			$line = "";
			@lines = ();
			while (length($msg) > 0) {
				push(@lines, substr($msg, 0, $charactersPerLine));
				$msg = substr($msg, $charactersPerLine);
			}
			@messageWords = undef;
		} else {
			if (length($line) + length($word) + 1 > $charactersPerLine) {
				push(@lines, $line);
				$line = "";
			}
			$line .= " " if ($line);
			$line .= $word;
		}
	}
	# Close out
	push(@lines, $line) if ($line);
	
	# Send messages
	if ($messageObj->content =~ /^\/me (.*)/) {
		$self->ircHandle->me($self->my_config->{channel}->{name}, $1);
		$self->eventAction($self->me, $messageObj->content);
	} else {
		foreach my $outLine (@lines) {
			$self->ircHandle->privmsg($self->my_config->{channel}->{name}, $outLine);
			$self->eventMessagePublic($self->me, $outLine);
			sleep(int(rand(2)));
		}
	}
}

###########
# INTERNAL
###########

# Event: Received a user action
sub cbAction {
	my ($self, $event) = @_;
	my ($message) = ($event->args);
	$self->{_whatbot}->eventAction($event->nick, $message);
}

# Event: Connected to server
sub cbConnect {
	my ($self, $event) = @_;
	$self->{_whatbot}->me($self->nick);
	
	# Join default channel
	$self->join($self->{_whatbot}->my_config->{channel}->{name},
				$self->{_whatbot}->my_config->{channel}->{channelpassword});
}

# Event: Disconnected from server
sub cbDisconnect {
	my ($self, $event) = @_;
	
	unless ($self->{_whatbot}->forceDisconnect) {
		$self->{_whatbot}->notify("Disconnected, attempting to reconnect...");
		sleep(1);
		$self->connect();
	}
}

# Event: User joined channel
sub cbJoin {
	my ($self, $event) = @_;
	$self->{_whatbot}->eventUserEnter($event->nick);
}

# Event: Received a public message
sub cbMessage {
	my ($self, $event) = @_;
	my ($message) = ($event->args);
	$self->{_whatbot}->eventMessagePublic($event->nick, $message, 1);
}

# Event: Received channel users
sub cbNames {
    my ($self, $event) = @_;
    my (@list, $channel) = ($event->args);
    ($channel, @list) = splice @list, 2;

    $self->{_whatbot}->notify($channel . " users: " . join(", ", @list));
	
	# When we get names, we've joined a room. If we have a join message, 
	# display it.
	if (defined $self->{_whatbot}->my_config->{channel}->{joinmessage}
		and ref($self->{_whatbot}->my_config->{channel}->{joinmessage}) ne 'HASH') {
		$self->privmsg($channel, $self->{_whatbot}->my_config->{channel}->{joinmessage});
	}
}

# Event: Attempted nick is taken
sub cbNickTaken {
	my ($self, $event) = @_;
	$self->{_whatbot}->my_config->{username} .= "_";
	$self->nick($self->{_whatbot}->my_config->{username});
	$self->{_whatbot}->me($self->nick);
}

# Event: User left a channel
sub cbPart {
	my ($self, $event) = @_;
	$self->{_whatbot}->eventUserLeave($event->nick);
}

# Event: Received CTCP Ping request
sub cbPing {
    my ($self, $event) = @_;
    my $nick = $event->nick;

    $self->ctcp_reply($nick, join (' ', ($event->args)));
    $self->{_whatbot}->notify("*** CTCP PING request from $nick received");
}

# Event: Received a private message
sub cbPrivateMessage {
	my ($self, $event) = @_;
	my ($nick, $message) = ($event->args);
	#$self->{_whatbot}->eventMessage($event->nick, $message, 2);
}

# Event: Channel topic change
sub cbTopic {
	my ($self, $event) = @_;
	my ($channel, $topic) = $event->args();

	if ($event->type() eq 'topic' and $channel =~ /^#/) {
		$self->{_whatbot}->notify("The topic for $channel is \"$topic\".");
	}
}

1;
