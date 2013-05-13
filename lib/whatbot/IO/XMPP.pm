###########################################################################
# whatbot/IO/XMPP.pm
###########################################################################
# whatbot XMPPconnector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;


# use Method::Signatures::Modifiers;

class whatbot::IO::XMPP extends whatbot::IO {
	use AnyEvent;
	use AnyEvent::Loop;
	use AnyEvent::XMPP::Client;
	use AnyEvent::XMPP::Ext::MUC;
	use AnyEvent::XMPP::Ext::Disco;
	use AnyEvent::XMPP::Util qw/node_jid res_jid/;
	use Data::Dumper;
	$Data::Dumper::Indent = 1;
	$Data::Dumper::Sortkeys = 1;
	$Data::Dumper::Useqq = 1;
	use HTML::Strip;
	use whatbot::Message;


    has 'handle' => (
            is  => 'rw',
            isa => 'AnyEvent::XMPP::Client',
    );
    has 'xmpp_handle' => (
            is  => 'ro',
            isa => 'AnyEvent::XMPP::Client',
    );
	has 'muc_handle' => (
			is 	=> 'rw',
			isa	=> 'AnyEvent::XMPP::Ext::MUC',
	);
    has 'force_disconnect' => (
            is  => 'rw',
            isa => 'Int',
    );
    has 'rooms' => (
            is         => 'ro',
            isa        => 'ArrayRef',
            lazy_build => 1,
    );
    has 'rooms_hash' => (
            is      => 'ro',
            isa     => 'HashRef',
            default => sub { {} },
    );

    sub _build_rooms {
            my ($self) = @_;
            my $rooms = $self->my_config->{'rooms'};
            $rooms = [$rooms] unless ( ref($rooms) eq 'ARRAY' );
            return $rooms;
    }


    method BUILD ($) {
            my $name = 'XMPP_' . $self->my_config->{'host'};
            $name =~ s/ /_/g;
            $self->name($name);
            $self->me( $self->my_config->{'nick'} );
    }

    after connect {
            my $config = $self->my_config;
            my $handle = AnyEvent::XMPP::Client->new ();
			my $disco = AnyEvent::XMPP::Ext::Disco->new;
			my $muc = AnyEvent::XMPP::Ext::MUC->new (disco => $disco, connection => $handle);
			$self->handle ($handle);
			# $self->muc_handle ($muc);
			$self->handle->add_extension ($disco);
			$self->handle->add_extension ($muc);
			
            $self->log->write (
                    sprintf (
                            'Connecting to %s:%d.',
                            $config->{'host'},
                            $config->{'port'},
                    )
            );
			# Set the Default Presence information
			$handle->set_presence (undef, "I'm a whatbot!", 1);

			# Add the account information for the XMPP connection
            $handle->add_account (
                    $config->{'username'},
                    $config->{'hostpassword'},
                    $config->{'host'},
                    $config->{'port'},
            );

            # Set up all the callbacks
            $handle->reg_cb(
                    'connected' => sub { $self->cb_connected(@_); }
            );
            $handle->reg_cb(
                    'part' => sub { $self->cb_part(@_); }
            );
            $handle->reg_cb(
                    'message' => sub { $self->cb_recv_message(@_); }
            );
            $handle->reg_cb(
                    'registered' => sub { $self->cb_connect(@_); }
            );
            $handle->reg_cb(
                    'disconnect' => sub { $self->cb_disconnect(@_); }
            );
            $handle->reg_cb(
                    'error' => sub { $self->cb_error(@_); }
            );
            $handle->reg_cb(
                    'session_ready' => sub { $self->cb_joinrooms(@_); }
            );
	
	# Start the connection:
	$handle->start();
    }

	method BUILD {
		my $name = 'XMPP_' . $self->my_config->{'username'};
		$name =~ s/ /_/g;
		$self->name ($name);
		$self->me ( $self->my_config->{'username'} );
	}

    method disconnect () {
            $self->force_disconnect (1);
            $self->handle->disconnect ( $self->my_config->{'quitmessage'} );
    }

	# Send a message
	method send_message ($message) {

		# Send messages
		my $msg_to = $message->to;
		my $content = $message->content;
		my $reply;
		my $message_body = $message->to;
		
		if ( $msg_to =~ '.*\[mucRoom\]' ) {
			my ($room) = ($msg_to =~ 's/^(.*)\[mucRoom\]$/');
			$reply = $self->muc_handle->make_reply ($message->content, $room, $self->handle->get_account);
			return;
		} else {
			$reply = $self->handle->send_message ($message->content, $message->to, $self->handle->get_account);
		}
	}

	#
	# INTERNAL
	#

	# Event: Received a message
	method cb_recv_message ( $connection, $account, $message ) {
		my $from       	= $message->from;
		my $listener 	= $self->handle;
		my ($username) 	= $from =~ /^(\S+)\//;

		$listener->event_message ( 
			whatbot::Message->new ( 
				{	'to'	  => $username,
					'from'    => $from,
					'content' => $message->any_body
				}
			)
		)
	}

	# Event: Room message recieved
	method cb_room_message ( $connection, $room, $message, $is_echo){
		return if $is_echo;
		return if $message->is_delayed;
		
		my $from 		= $message->from;
		my $to 			= $message->to;
		my $content 	= $message->any_body;
		my ($username) = $from =~ /^(\S+)\//;

		$self->event_message ( 
			whatbot::Message->new (
			{	'to'		=> $username."[mucRoom]",
				'from'		=> $from,
				'content' 	=> $content,
			}
			)
		)
	}

	# Event: Connected
	method cb_connected ( $connection, $account ){
		$self->notify ( $account->jid, 'Connected successfully.' );
	}

	# Event: Error
	method cb_error( $account, $account, $error, $test1? ) {
		print Dumper $error;
		
		$self->notify ($error);
	}

    # Event: connected and session established, join rooms
	method cb_joinrooms ( $connection, $account )  {

		$self->handle->add_extension (my $disco = AnyEvent::XMPP::Ext::Disco->new);
   		$self->handle->add_extension (my $muc = AnyEvent::XMPP::Ext::MUC->new (disco => $disco));

       	foreach my $room (@{ $self->rooms }) {
			$self->notify ( $account->jid, 'Joining Room '.$room->{'name'} );
			$muc->join_room ($account->connection, $room->{'name'}, node_jid $account->jid);
			$muc->reg_cb (
				'message' 			=> sub { $self->cb_room_message (@_); }
            )
            $muc->reg_cb(
                'part' 				=> sub { $self->part (@_); }
            )
            $muc->reg_cb(
                'subject_change' 	=> sub { $self->subject_change (@_); }
            )
		}
	}
    # Event: Disconnected from server
    method cb_disconnect ( $event ) {
    	unless ( $self->force_disconnect ) {
                    $self->notify( 'X', 'Disconnected, attempting to reconnect...');
                    sleep(3);
                    $self->connect();
            }
    }
    method cb_join ( $client, $nick, $channel, $is_myself ) {
        return if ($is_myself);
        $self->event_user_enter ( $channel, $nick );
        return;
    }

    # Event: Received a message
   	method cb_recv_message ( $connection, $acc, $msg  ) {
        my $from       	= $msg->from;
		my $listener 	= $self;
        my ($username) 	= $from =~ /^(\S+)\//;

        $listener->event_message (
			whatbot::Message->new (
				{'from'    => $username,
                'to'      => $from,
                'content' => $msg->any_body
       			}
			)
		)
    }

    # Event: User left a channel
    method cb_part ( $room, $user ) {
        $self->event_user_leave ( $room, $user );
    }

    # Event: Received CTCP Ping request
    method cb_ping ( $client, $source, $target, $message, $type ) {
            $self->ctcp_reply ( $source, $message );
            $self->notify ( '*', '*** CTCP PING request from $source received');
    }

    # Event: Channel topic change
    method subject_change ( $client, $channel, $topic?, $who? ) {
        return unless ( $channel =~ /^#/ );
        $self->notify ( $channel, sprintf( '*** The topic is \'%s\'.', $topic ) );
    }

}

1;
