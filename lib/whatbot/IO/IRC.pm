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

has 'handle'            => ( is => 'rw' );
has 'irc_handle'        => ( is => 'ro', isa => 'Net::IRC::Connection' );
has 'force_disconnect'  => ( is => 'rw', isa => 'Int' );

sub BUILD {
	my ( $self ) = @_;
	
	my $name = 'IRC_' . $self->my_config->{'host'} . '_' . $self->my_config->{'channel'}->{'name'};
	$name =~ s/ /_/g;
	$self->name($name);
	$self->me( $self->my_config->{'nick'} );
}

sub connect {
	my ( $self ) = @_;
	
	my $handle = new Net::IRC;
	$self->handle($handle);
	$self->log->write(
		'Connecting to ' . 
		$self->my_config->{'host'} . ':' . $self->my_config->{'port'} . 
		'.');
	
	# Net::IRC Connection Parameters
	$self->{'irc_handle'} = $self->handle->newconn(
		'Server'	=> $self->my_config->{'host'},
		'Port'		=> $self->my_config->{'port'},
		'Username'	=> $self->my_config->{'username'},
		'Ircname'	=> $self->my_config->{'realname'},
		'Password'	=> $self->my_config->{'hostpassword'},
		'Nick'		=> $self->my_config->{'nick'},
	);
	
	# Everything's event based, so we set up all the callbacks
	$self->irc_handle->add_handler('msg',		\&cb_private_message);
	$self->irc_handle->add_handler('public',	\&cb_message);
	$self->irc_handle->add_handler('caction',	\&cb_action);
	$self->irc_handle->add_handler('join',		\&cb_join);
	$self->irc_handle->add_handler('part',		\&cb_part);
	$self->irc_handle->add_handler('cping',		\&cb_ping);
	$self->irc_handle->add_handler('topic',		\&cb_topic);
	$self->irc_handle->add_handler('notopic',	\&cb_topic);
	
	$self->irc_handle->add_global_handler(376, 			\&cb_connect);
	$self->irc_handle->add_global_handler('disconnect', \&cb_disconnect);
	$self->irc_handle->add_global_handler(353, 			\&cb_names);
	$self->irc_handle->add_global_handler(433, 			\&cb_nick_taken);
	
	# I can't figure out how else to use this module in an OO way,
	# so I just do hax. They say if it takes a lot of work, you aren't
	# doing it right. Fine. Tell me how to fix this, then, and don't
	# say POE::Component::IRC. infobot hasn't released a new version
	# because they're moving to POE. Rapid development my behind.
	$self->irc_handle->{'_whatbot'} = $self;
	
	# Now we start one event loop so we can actually connect.
	$self->handle->do_one_loop();
	
}

sub disconnect {
	my ($self) = @_;
	
	$self->force_disconnect(1);
	$self->irc_handle->quit( $self->my_config->{'quitmessage'} );
}

sub event_loop {
	my ($self) = @_;
	
	$self->handle->do_one_loop();
}

# Send a message
sub send_message {
	my ($self, $message) = @_;
	
	# We're going to try and be smart.
	my $characters_per_line = 450;
	if (
	    defined( $self->my_config->{'charactersperline'} ) 
	    and ref( $self->my_config->{'charactersperline'} ) ne 'HASH'
	) {
		$characters_per_line = $self->my_config->{'charactersperline'};
	}
	my @lines;
	my @message_words = split(/\s/, $message->content);
	
	# If any of the words are over our maxlength, then let Net::IRC split it.
	# Otherwise, it's probably actual conversation, so we should split words.
	my $line = '';
	foreach my $word (@message_words) {
		if ( length($word) > $characters_per_line ) {
			my $msg = $message->content;
			$line = '';
			@lines = ();
			while ( length($msg) > 0 ) {
				push( @lines, substr($msg, 0, $characters_per_line) );
				$msg = substr( $msg, $characters_per_line );
			}
			@message_words = undef;
		} else {
			if ( length($line) + length($word) + 1 > $characters_per_line ) {
				push(@lines, $line);
				$line = '';
			}
			$line .= ' ' if ($line);
			$line .= $word;
		}
	}
	# Close out
	push(@lines, $line) if ($line);
	
	# Send messages
	if ( $message->content =~ /^\/me (.*)/ ) {
		$self->irc_handle->me( $self->my_config->{'channel'}->{'name'}, $1 );
		$self->event_action( $self->me, $message->content );
	} else {
		foreach my $outLine (@lines) {
			$self->irc_handle->privmsg( $self->my_config->{'channel'}->{'name'}, $outLine );
			$self->event_message_public( $self->me, $outLine );
			sleep( int(rand(2)) );
		}
	}
}

###########
# INTERNAL
###########

# Event: Received a user action
sub cb_action {
	my ( $self, $event ) = @_;
	
	my ($message) = ( $event->args );
	$self->{'_whatbot'}->event_action( $event->nick, $message );
}

# Event: Connected to server
sub cb_connect {
	my ( $self, $event ) = @_;
	
	$self->{'_whatbot'}->me( $self->nick );
	
	# Join default channel
	$self->join(
	    $self->{'_whatbot'}->my_config->{'channel'}->{'name'},
		$self->{'_whatbot'}->my_config->{'channel'}->{'channelpassword'}
	);
}

# Event: Disconnected from server
sub cb_disconnect {
	my ( $self, $event ) = @_;
	
	unless ( $self->{'_whatbot'}->force_disconnect ) {
		$self->{'_whatbot'}->notify('Disconnected, attempting to reconnect...');
		sleep(1);
		$self->connect();
	}
}

# Event: User joined channel
sub cb_join {
	my ( $self, $event ) = @_;
	
	$self->{'_whatbot'}->event_user_enter( $event->nick );
}

# Event: Received a public message
sub cb_message {
	my ( $self, $event ) = @_;
	
	my ($message) = ( $event->args );
	$self->{'_whatbot'}->event_message_public( $event->nick, $message, 1 );
}

# Event: Received channel users
sub cb_names {
    my ( $self, $event ) = @_;
    
    my ( @list, $channel ) = ( $event->args );
    ( $channel, @list ) = splice( @list, 2 );

    $self->{'_whatbot'}->notify( $channel . ' users: ' . join(', ', @list) );
	
	# When we get names, we've joined a room. If we have a join message, 
	# display it.
	if (
	    defined $self->{'_whatbot'}->my_config->{'channel'}->{'joinmessage'}
		and ref($self->{'_whatbot'}->my_config->{'channel'}->{'joinmessage'}
	) ne 'HASH') {
		$self->privmsg( $channel, $self->{'_whatbot'}->my_config->{'channel'}->{'joinmessage'} );
	}
}

# Event: Attempted nick is taken
sub cb_nick_taken {
	my ( $self, $event ) = @_;
	
	$self->{'_whatbot'}->my_config->{'username'} .= '_';
	$self->nick( $self->{'_whatbot'}->my_config->{'username'} );
	$self->{'_whatbot'}->me( $self->nick );
}

# Event: User left a channel
sub cb_part {
	my ( $self, $event ) = @_;
	
	$self->{'_whatbot'}->event_user_leave($event->nick);
}

# Event: Received CTCP Ping request
sub cb_ping {
    my ( $self, $event ) = @_;
    
    my $nick = $event->nick;
    $self->ctcp_reply( $nick, join ( ' ', ($event->args) ) );
    $self->{'_whatbot'}->notify('*** CTCP PING request from $nick received');
}

# Event: Received a private message
sub cb_private_message {
	my ( $self, $event ) = @_;
	
	my ( $nick, $message ) = ( $event->args );
	#$self->{'_whatbot'}->event_message($event->nick, $message, 2);
}

# Event: Channel topic change
sub cb_topic {
	my ( $self, $event ) = @_;
	
	my ($channel, $topic) = $event->args();
	if ( $event->type() eq 'topic' and $channel =~ /^#/ ) {
		$self->{'_whatbot'}->notify('The topic for $channel is \'$topic\'.');
	}
}

1;
