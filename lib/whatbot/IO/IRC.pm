###########################################################################
# whatbot/IO/IRC.pm
###########################################################################
#
# whatbot IRC connector
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::IO::IRC extends whatbot::IO {
	use Net::IRC;

	has 'handle'            => ( is => 'rw' );
	has 'irc_handle'        => ( is => 'ro', isa => 'Net::IRC::Connection' );
	has 'force_disconnect'  => ( is => 'rw', isa => 'Int' );

	method BUILD ($) {
		my $name = 'IRC_' . $self->my_config->{'host'};
		$name =~ s/ /_/g;
		$self->name($name);
		$self->me( $self->my_config->{'nick'} );
	}

	method connect {
		my $handle = Net::IRC->new();
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
			'SSL'       => ( $self->my_config->{'ssl'} ? 1 : undef )
		);
	
		# Everything's event based, so we set up all the callbacks
		$self->irc_handle->add_handler('msg',		\&cb_message);
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
	
		# I can't figure out how else to use this module in an OO way, so I just do
		# hax. They say if it takes a lot of work, you aren't doing it right.
		# Fine. Tell me how to fix this, then, and don't say
		# POE::Component::IRC. infobot hasn't released a new version because
		# they're moving to POE. Rapid development my behind.
		$self->irc_handle->{'_whatbot'} = $self;
	
		# Now we start one event loop so we can actually connect.
		$self->handle->do_one_loop();
		binmode( $self->irc_handle->socket, ":utf8" );
	}

	method disconnect {
		$self->force_disconnect(1);
		$self->irc_handle->quit( $self->my_config->{'quitmessage'} );
	}

	method event_loop {
		$self->handle->do_one_loop();
	}

	# Send a message
	method send_message( $message ) {
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
		push( @lines, $line ) if ($line);
	
		# Send messages
		if ( $message->content =~ /^\/me (.*)/ ) {
			$self->irc_handle->me( $message->to, $1 );
			$self->event_action( $self->me, $message->from, $message->content );
		} else {
			foreach my $out_line (@lines) {
				$self->irc_handle->privmsg( $message->to, $out_line );
				$message->content($out_line);
				$self->event_message($message);
				sleep( int(rand(2)) );
			}
		}
	}

	###########
	# INTERNAL
	###########

	# Event: Received a user action
	method cb_action( $event ) {
		my ($message) = ( $event->args );
		$self->{'_whatbot'}->event_action( $event->to->[0], $event->nick, $message );
	}

	# Event: Connected to server
	method cb_connect( $event ) {
		$self->{'_whatbot'}->me( $self->nick );
	
		# Join default channel(s)
		my $channels = $self->{'_whatbot'}->my_config->{'channel'};
		$channels = [$channels] unless ( ref($channels) eq 'ARRAY' );
		foreach my $channel (@$channels) {
			$self->join(
				$channel->{'name'},
				$channel->{'channelpassword'}
			);
			$self->{'_wb_channels'}->{ $channel->{'name'} } = $channel;
		}
	}

	# Event: Disconnected from server
	method cb_disconnect( $event ) {
		unless ( $self->{'_whatbot'}->force_disconnect ) {
			$self->{'_whatbot'}->notify( 'X', 'Disconnected, attempting to reconnect...');
			sleep(3);
			$self->{'_whatbot'}->connect();
		}
	}

	# Event: User joined channel
	method cb_join( $event ) {
		$self->{'_whatbot'}->event_user_enter( $event->to->[0], $event->nick );
	}

	# Event: Received a public message
	method cb_message( $event ) {
		my ($message) = ( $event->args );
		$self->{'_whatbot'}->event_message( $self->{'_whatbot'}->get_new_message({
			'from'    => $event->nick,
			'to'      => $event->to->[0],
			'content' => $message,
		}) );
	}

	# Event: Received channel users
	method cb_names( $event ) {
		my ( @list, $channel ) = ( $event->args );
		( $channel, @list ) = splice( @list, 2 );

		$self->{'_whatbot'}->notify( $channel, 'users: ' . join(', ', @list) );
	
		# When we get names, we've joined a room. If we have a join message, 
		# display it.
		if (
			defined $self->{'_wb_channels'}->{$channel}->{'joinmessage'}
			and ref($self->{'_wb_channels'}->{$channel}->{'joinmessage'}
		) ne 'HASH') {
			$self->privmsg( $channel, $self->{'_wb_channels'}->{$channel}->{'joinmessage'} );
		}
	}

	# Event: Attempted nick is taken
	method cb_nick_taken( $event ) {
		$self->{'_whatbot'}->my_config->{'username'} .= '_';
		$self->nick( $self->{'_whatbot'}->my_config->{'username'} );
		$self->{'_whatbot'}->me( $self->nick );
	}

	# Event: User left a channel
	method cb_part( $event ) {
		$self->{'_whatbot'}->event_user_leave( $event->to->[0], $event->nick );
	}

	# Event: Received CTCP Ping request
	method cb_ping( $event ) {
		my $nick = $event->nick;
		$self->ctcp_reply( $nick, join ( ' ', ($event->args) ) );
		$self->{'_whatbot'}->notify('*** CTCP PING request from $nick received');
	}

	# Event: Channel topic change
	method cb_topic( $event ) {
		my ( $channel, $topic ) = $event->args();
		if ( $event->type() eq 'topic' and $channel =~ /^#/ ) {
			$self->{'_whatbot'}->notify('The topic for $channel is \'$topic\'.');
		}
	}
}

1;

