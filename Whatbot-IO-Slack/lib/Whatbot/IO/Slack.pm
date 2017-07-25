###########################################################################
# Slack.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

BEGIN { 
	$Whatbot::IO::Slack::VERSION = '0.2';
}

class Whatbot::IO::Slack extends Whatbot::IO {
	use AnyEvent::SlackRTM;
	use Data::Dumper;
	use Encode;
	use Whatbot::Utility;

	has 'handle' => (
		is  => 'rw',
		isa => 'AnyEvent::SlackRTM',
	);
	has 'force_disconnect' => (
		is  => 'rw',
		isa => 'Int',
	);
	has 'token' => (
		is  => 'rw',
		isa => 'Str',
	);
	has 'users' => (
		is  => 'ro',
		isa => 'HashRef',
		default => sub { {} }
	);
	has 'channels' => (
		is  => 'ro',
		isa => 'HashRef',
		default => sub { {} }
	);

	method BUILD (...) {
		die 'IO->Slack is missing an access token' unless ( $self->my_config->{'token'} );
		$self->token( $self->my_config->{'token'} );

		$self->slack_name($self->token);
	}

	after connect {
		my $config = $self->my_config;
		my $rtm = AnyEvent::SlackRTM->new($self->token);
		$self->handle($rtm);
		$self->register_callbacks();
		$self->{'_timer_connect'} = AnyEvent->timer(
			after    => 4,
			cb       => sub {
				$self->log->write('Connecting to Slack.');
				$rtm->start();
			},
		);
	};

	method disconnect () {
		$self->force_disconnect(1);
		if ( $self->handle ) {
			$self->handle->close();
		}
	}

	# Send a message
	method deliver_message ( $message ) {
		my $to;
		foreach my $channel ( keys %{ $self->channels } ) {
			if ( $self->channels->{$channel} eq $message->to ) {
				$to = $channel;
			}
		}
		unless ($to) {
			$self->log->write('Could not find target channel for: ' . $message->to);
			return;
		}
		$self->handle->send({
			'type'    => 'message',
			'channel' => $to,
			'text'    => $message->content,
		});
		$self->event_message($message);
		return;
	}

	method format_user($user) {
		$user =~ s/^\@//;
		foreach my $id ( keys %{ $self->users } ) {
			my $name = $self->users->{$id};
			if ( $name eq $user ) {
				return sprintf( '<@%s|%s>', $id, $name );
			}
		}

		return $user;
	}

	### INTERNAL

	method slack_name($name) {
		$self->name( 'Slack_' . $name );
		return;
	}

	method register_callbacks() {
		my $rtm = $self->handle;

		$rtm->on( 'hello' => sub { $self->_hello($rtm); } );
		$rtm->on( 'message' => sub { $self->_message(@_); } );
		$rtm->on( 'finish' => sub { $self->_finish(@_); } );
		$rtm->on( 'channel_created' => sub { $self->_channel_created(@_); } );
		$rtm->on( 'channel_joined' => sub { $self->_channel_joined(@_); } );
		$rtm->on( 'channel_join' => sub { $self->_channel_join(@_); } );
		$rtm->on( 'user_change' => sub { $self->_user_change(@_); } );
	}

	method _hello($rtm) {
		$self->log->write('Connected to Slack.');

		# Read metadata soon
		$self->{'_timer_metadata'} = AnyEvent->timer(
			after    => 5,
			cb       => sub {
				# Fill user table
				my $metadata = $rtm->metadata();

				foreach my $user ( @{ $metadata->{'users'} } ) {
					$self->users->{ $user->{'id'} } = $user->{'name'};
				}

				# Fill channel table
				foreach my $channel ( @{ $metadata->{'channels'} } ) {
					$self->channels->{ $channel->{'id'} } = $channel->{'name'};
				}

				# Set me
				$self->me( $metadata->{'self'}->{'name'} );

				$self->log->write('Slack initialized.');

				# $rtm->on( 'presence_change' => sub { $self->_presence_change(@_); } );
			}
		);
	}

	method _message( $rtm, $message ) {
		return if ($message->{'hidden'} or $message->{'thread_ts'} or not scalar( %{ $self->users } ) );
		$self->event_message( $self->_slack_message_to_message($message) );
		return;
	}

	method _channel_joined( $rtm, $event ) {
		$self->log->write('** Joined ' . $event->{'channel'}->{'name'} );
		return;
	}

	method _channel_join( $rtm, $event ) {
		$self->log->write(Data::Dumper::Dumper($event));
		# 		$self->event_user_join( $channel, $nick, $message );
		return;
	}

	method _channel_leave( $rtm, $event ) {
		$self->log->write(Data::Dumper::Dumper($event));
		# 		$self->event_user_leave( $channel, $nick, $message );
		return;
	}

	method _finish($rtm) {
		$self->log->write('Disconnected from Slack.');
		$self->force_disconnect(0);
		$self->{'_timer_metadata'} = undef;
		foreach my $user ( keys %{ $self->users } ) {
			delete( $self->users->{$user} );
		}
		foreach my $channel ( keys %{ $self->channels } ) {
			delete( $self->channels->{$channel} );
		}
		$self->{'_timer_reconnect'} = AnyEvent->timer(
			after    => 3,
			cb       => sub {
				# Reconnect in 3 seconds
				$self->connect();
			}
		);
	}

	method _channel_created( $rtm, $event ) {
		my $channel = $event->{'channel'};
		$self->channels->{ $channel->{'id'} } = $channel->{'name'};
		$self->log->write('New channel: ' . $channel->{'name'} );
	}

	method _user_change( $rtm, $event ) {
		my $user = $event->{'user'};
		$self->users->{ $user->{'id'} } = $user->{'name'};
		$self->log->write('New/changed user: ' . $user->{'name'} );
	}

	method _presence_change( $rtm, $event ) {
		my $user = $event->{'user'};
		my $username = $self->users->{ $user->{'id'} }->{'name'};
		$self->log->write(Data::Dumper::Dumper($event));
	}

	method _slack_message_to_message( $slack_message ) {
		my $text = $slack_message->{'text'};

		# Strip links
		$text =~ s/<(http.*?)>/$1/g;

		# Change users to Slack-provided user readable
		$text =~ s/<\@\w+?\|(\w+)>/$self->_get_user($1)/ge;

		# Change users to self-provided user readable
		$text =~ s/<\@(\w+?)>/$self->_get_user($1)/ge;

		my $content = Whatbot::Utility::html_strip($text);
		return $self->get_new_message({
			'from'    => $self->users->{ $slack_message->{'user'} },
			'to'      => $self->channels->{ $slack_message->{'channel'} },
			'content' => $content,
		});
	}

	method _get_user($id) {
		return $self->tag_user( $self->users->{$id} or $id );
	}

}

1;

=pod

=head1 NAME

Whatbot::IO::Slack - Provide Whatbot integration with Slack.

=head1 CONFIG

  "io": [
    {
      "interface": "Slack",
      "token": "my-slack-generated-bot-token",
      "channel": "opening-channel-identifier"
    }
  ]

=over 4

=item token

The access token generated through Slack when registering a bot user.

=item channel (optional)

Channel to immediately open when starting up, if any. Whatbot will respond to
any channel.

=back

=head1 DESCRIPTION

Whatbot::IO::Slack is designed to allow Whatbot to be used as a bot integration
on the Slack platform.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
