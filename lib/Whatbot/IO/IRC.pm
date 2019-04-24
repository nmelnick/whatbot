###########################################################################
# Whatbot/IO/IRC.pm
###########################################################################
#
# whatbot IRC connector
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::IO::IRC extends Whatbot::IO {
	use AnyEvent::IRC::Client;
	use Encode;

	has 'handle' => (
		is  => 'rw',
		isa => 'Maybe[AnyEvent::IRC::Client]',
	);
	has 'force_disconnect' => (
		is  => 'rw',
		isa => 'Int',
	);
	has 'channels' => (
		is         => 'ro',
		isa        => 'ArrayRef',
		lazy_build => 1,
	);
	has 'channels_hash' => (
		is      => 'ro',
		isa     => 'HashRef',
		default => sub { {} },
	);

	sub _build_channels {
		my ($self) = @_;
		my $channels = $self->my_config->{'channel'};
		$channels = [$channels] unless ( ref($channels) eq 'ARRAY' );
		return $channels;
	}

	method BUILD (...) {
		my $name = 'IRC_' . $self->my_config->{'host'};
		$name =~ s/ /_/g;
		$self->name($name);
		$self->me( $self->my_config->{'nick'} );
	}

	after connect {
		my $config = $self->my_config;
		my $handle = AnyEvent::IRC::Client->new();
		$self->handle($handle);
		$self->force_disconnect(0);
		$self->log->write(
			sprintf(
				'Connecting to %s:%d.',
				$config->{'host'},
				$config->{'port'},
			)
		);

		$handle->enable_ssl() if ( $config->{'ssl'} );

		$handle->connect(
			$config->{'host'},
			$config->{'port'},
			{
				'nick'     => $config->{'nick'},
				'user'     => $config->{'username'},
				'real'     => $config->{'realname'},
				'password' => $config->{'hostpassword'},
			},
		);

		# Set up all the callbacks
		$handle->reg_cb(
			'join' => sub { $self->cb_join(@_); }
		);
		$handle->reg_cb(
			'part' => sub { $self->cb_part(@_); }
		);
		$handle->reg_cb(
			'channel_topic' => sub { $self->cb_topic(@_); }
		);
		$handle->reg_cb(
			'privatemsg' => sub { $self->cb_message(@_); }
		);
		$handle->reg_cb(
			'publicmsg' => sub { $self->cb_message(@_); }
		);
		$handle->reg_cb(
			'registered' => sub { $self->cb_connect(@_); }
		);
		$handle->reg_cb(
			'disconnect' => sub { $self->cb_disconnect(@_); }
		);
		$handle->reg_cb(
			'ctcp_PING' => sub { $self->cb_ping(@_); }
		);
		$handle->reg_cb(
		 	'ctcp' => sub { $self->cb_ctcp(@_); }
		);
		$handle->reg_cb(
		 	'channel_change' => sub { $self->cb_channel_change(@_); }
		);

	}

	method disconnect () {
		$self->force_disconnect(1);
		$self->handle->disconnect( $self->my_config->{'quitmessage'} );
	}

	# Send a message
	method deliver_message ( $message ) {
		# We're going to try and be smart.
		my $characters_per_line = 502 - length( $message->to ) - 10;
		my @lines;
		my @message_words = split( /\s/, $message->content );

		# If any of the words are over our maxlength, then let IRC split it.
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
			$self->event_action( $self->me, $message->from, $message->content );
		} else {
			foreach my $out_line (@lines) {
				$self->privmsg( $message->to, $out_line );
				$message->content($out_line);
				$self->event_message($message);
				sleep( int(rand(2)) );
			}
		}
	}

	###########
	# INTERNAL
	###########

	method privmsg ( $to, $message ) {
		$self->handle->send_srv(
			'PRIVMSG' => $to,
			encode( 'utf-8', $message ),
		);
		return;
	}

	# Event: Received a CTCP message
	method cb_ctcp ( $client, $source, $target, $tag, $message, $type ) {
		return if ( $tag eq 'PING' );
		if ( $tag eq 'ACTION' and $type eq 'PRIVMSG' ) {
			$self->event_action( $target, $source, $message );
		}
		return;
		# warn sprintf( 'CTCP: %s -> %s, tag %s, type %s: %s', $source, $target, $tag, $type, $message );
	}

	# Event: Connected to server
	method cb_connect ( $client ) {
		$self->me( $self->handle->nick );

		# Join default channel(s)
		foreach my $channel ( @{ $self->channels } ) {
			my $name = $channel->{'name'};
			$client->send_srv( 'JOIN', $name, $channel->{'channelpassword'} );
			$self->channels_hash->{ $name } = $channel;
			$self->notify( $name, 'Joined.' );

			if ( defined $channel->{'joinmessage'} ) {
				$self->privmsg( $name, $channel->{'joinmessage'} );
			}
		}
		return;
	}

	# Event: Disconnected from server
	method cb_disconnect ( $client, ... ) {
		unless ( $self->force_disconnect ) {
			$self->handle(undef);
			$self->notify( 'X', 'Disconnected, attempting to reconnect...');
			sleep(3);
			$self->connect();
		}
		return;
	}

	# Event: User joined channel
	method cb_join( $client, $nick, $channel, $is_myself ) {
		return if ($is_myself);
		$self->event_user_enter( $channel, $nick );
		return;
	}

	# Event: User left a channel
	method cb_part( $client, $nick, $channel, $is_myself, $message ) {
		return if ($is_myself);
		$self->event_user_leave( $channel, $nick, $message );
		return;
	}

	# Event: Received a message
	method cb_message( $client, $to, $irc_message ) {
		#return if ( $irc_message->{'command'} eq 'NOTICE' );
		my $nick = $irc_message->{'prefix'};
		return unless ($nick);
		$nick =~ s/!.*//;
		my $message = $irc_message->{'params'}->[-1];
		eval {
			$message = decode( 'utf-8', $message );
		};
		$self->event_message(
			$self->get_new_message({
				'from'    => $nick,
				'to'      => $to,
				'content' => $message,
			})
		);
		return;
	}

	# Event: Received CTCP Ping request
	method cb_ping( $client, $source, $target, $message, $type ) {
		$self->ctcp_reply( $source, $message );
		$self->notify( '*', '*** CTCP PING request from $source received');
		$self->event_ping($source);
	}

	# Event: Channel topic change
	method cb_topic( $client, $channel, $topic?, $who? ) {
		return unless ( $channel =~ /^#/ );
		eval {
			$topic = decode( 'utf-8', $topic );
		};
		$self->notify( $channel, sprintf( '*** The topic is \'%s\'.', $topic ) );
		$self->event_topic( $channel, $topic, $who );
	}

	# Event: User changed nickname
	method cb_channel_change( $client, $message, $channel, $old_nick, $new_nick, $is_myself? ) {
		return if ($is_myself);
		$self->event_user_change( $channel, $old_nick, $new_nick );
		return;
	}
}

1;
