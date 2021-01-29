###########################################################################
# Discord.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

BEGIN { 
	$Whatbot::IO::Discord::VERSION = '0.1';
}

class Whatbot::IO::Discord extends Whatbot::IO {
	use AnyEvent::Discord;
	use Data::Dumper;
	use Encode;
	use Whatbot::Utility;

	has 'handle' => (
		is  => 'rw',
		isa => 'AnyEvent::Discord',
	);
	has 'force_disconnect' => (
		is  => 'rw',
		isa => 'Int',
	);
	has 'token' => (
		is  => 'rw',
		isa => 'Str',
	);
	has '_typing_handle' => (
		is  => 'rw',
	);

	method BUILD (...) {
		die 'IO->Discord is missing an access token' unless ( $self->my_config->{'token'} );
		$self->token( $self->my_config->{'token'} );
		$self->discord_name($self->token);
	}

	after connect {
		my $config = $self->my_config;
		my $client = AnyEvent::Discord->new(
      token => $self->token
    );
    $client->on('ready', sub { $self->_connected(@_) });
    $client->on('disconnected', sub { $self->_disconnected(@_) });
    $client->on('message_create', sub { $self->_message(@_) });
		$self->handle($client);
		$self->{'_timer_connect'} = AnyEvent->timer(
			after    => 3,
			cb       => sub {
				$self->log->write('Connecting to Discord.');
				$client->connect();
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
		foreach my $channel ( keys %{ $self->handle->channels } ) {
			if ( $self->handle->channels->{$channel} eq $message->to ) {
				$to = $channel;
			}
		}
		unless ($to) {
			$self->log->write('Could not find target channel for: ' . $message->to);
			return;
		}
		$self->handle->send($to, $message->content);
		$self->handle->_socket->close();
		return;
	}

	method format_user($user) {
		$user =~ s/^\@//;
		foreach my $id ( keys %{ $self->handle->users } ) {
			my $name = $self->handle->users->{$id};
			if ( $name eq $user ) {
				return sprintf( '<@!%s>', $id );
			}
		}

		return $user;
	}

	method start_typing($message_to) {
		$self->{_typing_handle} = undef;
		my $to;
		foreach my $channel ( keys %{ $self->handle->channels } ) {
			if ( $self->handle->channels->{$channel} eq $message_to ) {
				$to = $channel;
			}
		}
		return unless ($to);
		$self->_typing_handle($self->handle->typing($to));
	}

	method stop_typing() {
		$self->{_typing_handle} = undef;
	}

	### INTERNAL

	method discord_name($name) {
		$self->name( 'Discord_' . $name );
		return;
	}

  method _connected($client, $data, $op) {
    $self->log->write('Connected to Discord.');
		$self->me( $data->{'user'}->{'username'} );
	}

  method _disconnected {
    $self->log->write('Discord received disconnect.');;
	}

	method _message( $client, $data, $op ) {
		my $text = $data->{'content'};

		# Strip links
		$text =~ s/<(http.*?)>/$1/g;

		# Change users to self-provided user readable
		$text =~ s/<\@(\w+?)>/$self->_get_user($1)/ge;

		my $content = Whatbot::Utility::html_strip($text);
		return $self->event_message(
      $self->get_new_message({
        'from'    => $data->{'author'}->{'username'},
        'to'      => $client->channels->{$data->{'channel_id'}},
        'content' => $content,
      })
    );
	}

	method _get_user($id) {
		return unless ($id);
		return $self->tag_user( $self->handle->users->{$id} or $id );
	}

}

1;

=pod

=head1 NAME

Whatbot::IO::Discord - Discord Whatbot integration with Slack.

=head1 CONFIG

  "io": [
    {
      "interface": "Slack",
      "token": "my-discord-generated-bot-token"
    }
  ]

=over 4

=item token

The access token generated through Discord when registering a bot user.

=item channel (optional)

Channel to immediately open when starting up, if any. Whatbot will respond to
any channel.

=back

=head1 DESCRIPTION

Whatbot::IO::Discord is designed to allow Whatbot to be used as a bot
integration on the Discord platform.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
