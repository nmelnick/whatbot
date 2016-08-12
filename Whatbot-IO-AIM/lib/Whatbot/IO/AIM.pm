###########################################################################
# Whatbot/IO/AIM.pm
###########################################################################
# whatbot AIM connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

BEGIN {
	$Whatbot::IO::AIM::VERSION = '0.2';
}

class Whatbot::IO::AIM extends Whatbot::IO::Legacy {
	use Net::OSCAR qw(:standard);
	use Whatbot::Message;
	use Whatbot::Utility;

	has 'aim_handle' => ( is => 'rw' );
	has 'rooms'      => ( is => 'ro', default => sub { [] } );
	has 'room_chat'  => ( is => 'ro', default => sub { {} } );

	method BUILD(...) {
		die 'AIM component requires a "screenname" and a "password"' unless (
			$self->my_config->{'screenname'}
			and $self->my_config->{'password'}
		);

		my $name = 'AIM_' . $self->my_config->{'screenname'};
		$name =~ s/ /_/g;
		$self->name($name);
		$self->me( $self->my_config->{'screenname'} );
		if ( $self->my_config->{'rooms'} ) {
			my $rooms = $self->my_config->{'rooms'};
			$rooms = [$rooms] unless ( ref($rooms) );
			push( @{ $self->rooms }, @$rooms );
		}
	}

	after connect() {
		# Create Object
		my $oscar = Net::OSCAR->new();
	
		# Set callbacks
		$oscar->set_callback_im_in(\&cb_message);
		$oscar->set_callback_signon_done(\&cb_connected);
		$oscar->set_callback_error(\&cb_error);
		$oscar->set_callback_snac_unknown( sub {} );
		$oscar->set_callback_chat_buddy_in(\&cb_chat_join);
		$oscar->set_callback_chat_buddy_out(\&cb_chat_part);
		$oscar->set_callback_chat_im_in(\&cb_chat_message);
		$oscar->set_callback_chat_joined(\&cb_chat_joined);
	
		# Sign on
		$oscar->signon(
			$self->my_config->{'screenname'},
			$self->my_config->{'password'}
		);
		$oscar->{'_whatbot'} = $self;
		$self->aim_handle($oscar);
		return $self->aim_handle->do_one_loop();
	}

	method disconnect {
		return $self->aim_handle->signoff();
	}

	method event_loop {
		eval {
			$self->aim_handle->do_one_loop();
		};
		if ($@) {
			$self->log->error($@);
		}
		return;
	}

	# Send a message
	method send_message( $message ) {
		# We're going to try and be smart.
		my $characters_per_line = '1024';
		if (
			defined($self->my_config->{'charactersperline'}) 
			and ref($self->my_config->{'charactersperline'}) ne 'HASH'
		) {
			$characters_per_line = $self->my_config->{'charactersperline'};
		}
		my @lines;
		my @message_words = split( /\s/, $message->content );
	
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
				if (length($line) + length($word) + 1 > $characters_per_line) {
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
		foreach my $out_line (@lines) {
			my $result;
			if ( $self->room_chat->{$message->to} ) {
				$result = $self->room_chat->{$message->to}->chat_send($out_line);
			} else {
				$result = $self->aim_handle->send_im( $message->to, $out_line );
			}
			if ($result > 0) {
				$message->content($out_line);
				$self->event_message($message);
			} else {
				$self->notify('Message could not be sent');
			}
		
		}
	}

	#
	# INTERNAL
	#

	# Event: Received a private message
	method cb_message( $from?, $message?, $is_away_response? ) {
		$message = Whatbot::Utility::html_strip($message);
		$message =~ s/^[^A-z0-9]+//;
		$message =~ s/[\s]+$//;
		$self->{'_whatbot'}->event_message( Whatbot::Message->new({
			'from'       => $$from,
			'to'         => $self->{'_whatbot'}->me,
			'content'    => $message,
			'is_private' => 1
		}) ) unless ( $is_away_response );
	}

	# Event: Received a chat message
	method cb_chat_message( $from?, $chat?, $message? ) {
		$message = Whatbot::Utility::html_strip($message);
		$message =~ s/^[^A-z0-9]+//;
		$message =~ s/[\s]+$//;
		$self->{'_whatbot'}->event_message(
			$self->{'_whatbot'}->get_new_message(
				{
					'reply_to'   => $chat->name,
					'from'       => $from,
					'to'         => $chat->name,
					'content'    => $message,
					'me'         => $self->{'_whatbot'}->me,
					'is_private' => 0,
				}
			)
		);
		return;
	}

	# Event: Connected
	method cb_connected {
		$self->{'_whatbot'}->notify( '', 'Connected successfully.' );

		# Join chats
		foreach my $room ( @{ $self->{'_whatbot'}->rooms } ) {
			$self->{'_whatbot'}->log->write( 'Joining ' . $room );
			$self->chat_join($room);
		}
	}

	# Event: Error
	method cb_error( $connection, $error, $description, $fatal ) {
		$self->{'_whatbot'}->log->error($description);
	}

	# Event: User joined chat
	method cb_chat_join( $screenname, $chat, $buddy_data ) {
		return if ($screenname eq $self->{'_whatbot'}->me);
		$self->{'_whatbot'}->event_user_enter( $chat->name, $screenname );
		return;
	}

	# Event: User left chat
	method cb_chat_part( $screenname, $chat ) {
		return if ($screenname eq $self->me);
		$self->{'_whatbot'}->event_user_leave( $chat->name, $screenname );
		return;
	}

	# Event: We joined chat
	method cb_chat_joined( $chatname, $chat ) {
		$self->{'_whatbot'}->log->write('Joined "' . $chatname . '".');
		$self->{'_whatbot'}->room_chat->{$chatname} = $chat;
		return;
	}
}

1;

=pod

=head1 NAME

Whatbot::IO::AIM - Provide chat through AOL Instant Messenger.

=head1 CONFIG

 "io" : {
     "AIM" : {
         "screenname" : "myaimscreenname",
         "password" : "myaimpassword",
         "rooms" : [
         	"optionaltestroom"
         ]
     }
 }

=head1 DESCRIPTION

Whatbot::IO::AIM provides a connection interface to AIM/AOL Instant Messenger.
It only supports private chats, and not AOL chat rooms.

This uses Whatbot::IO::Legacy, as Net::OSCAR does not fit within any existing
event models.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
