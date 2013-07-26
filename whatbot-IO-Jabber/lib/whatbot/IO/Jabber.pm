###########################################################################
# whatbot/IO/Jabber.pm
###########################################################################
#
# whatbot Jabber connector
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::IO::Jabber extends whatbot::IO {
	use AnyEvent::XMPP::Client;
	use AnyEvent::XMPP::Ext::Version;
	use AnyEvent::XMPP::Ext::Disco;
	use AnyEvent::XMPP::Ext::MUC;
	use AnyEvent::XMPP::Util qw(res_jid split_jid node_jid);
	use Scalar::Util qw(weaken);
	use Encode;

	has 'handle' => (
		is  => 'rw',
		isa => 'AnyEvent::XMPP::Client',
	);
	has _muc => (
	  is => 'rw',
		isa => 'AnyEvent::XMPP::Ext::MUC',
		lazy_build => 1,
	);
	sub _build__muc {
		my $self = shift;
		return AnyEvent::XMPP::Ext::MUC->new(disco => $self->_disco);
	}
	has _disco => (
	  is => 'rw',
		isa => 'AnyEvent::XMPP::Ext::Disco',
		lazy_build => 1,
	);
	sub _build__disco {
		return AnyEvent::XMPP::Ext::Disco->new;
	}
	has _version => (
	  is => 'rw',
		isa => 'AnyEvent::XMPP::Ext::Version',
		default => sub {
			return AnyEvent::XMPP::Ext::Version->new
		}
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
		my $name = 'Jabber_' . $self->my_config->{'host'};
		$name =~ s/[\s\.]/_/g;
		$self->name($name);
		$self->me( $self->my_config->{'jabber_id'} );
	}

	after connect {
		my $config = $self->my_config;
		my $handle  = AnyEvent::XMPP::Client->new(debug => 0);
		my $version = AnyEvent::XMPP::Ext::Version->new;
		my $disco   = $self->_disco;
		my $muc     = $self->_muc;

		$handle->add_extension($disco);
		$handle->add_extension($version);
		$handle->add_extension($muc);

		$handle->add_account($config->{jabber_id}, $config->{password}, undef, undef, {dont_retrieve_roster => 1});

		$handle->set_presence(undef, $config->{presence_status}, $config->{presence_priority});

		$self->handle($handle);

		$self->log->write(
			sprintf(
				'Connecting to %s:%d.',
				$config->{'host'},
				$config->{'port'},
			)
		);

		$handle->start;

		weaken(my $s = $self);
		# Set up all the callbacks
		$handle->reg_cb(
			session_ready => sub { $s->cb_client_session_ready(@_); },
			disconnect => sub { $s->cb_client_disconnect(@_) },
			contact_request_subscribe => sub { $s->cb_client_contact_request_subscribe(@_); },
			error => sub { $s->cb_client_error(@_) },
			message => sub { $s->cb_client_message(@_) },
		);
		$muc->reg_cb(
		  message => sub { $self->cb_muc_message(@_) },
			join => sub { $self->cb_muc_join(@_) },
			part => sub { $self->cb_muc_part(@_) },
		);

	};

	method disconnect () {
		$self->force_disconnect(1);
		$self->handle->disconnect( $self->my_config->{'quitmessage'} );
	}

	# Send a message
	method send_message ( $message ) {
		$self->event_action( $self->me, $message->from, $message->content );
		$message->{from} ||= $self->my_config->{jabber_id};
		if ( my $account = $self->handle->find_account_for_dest_jid( $message->to ) ) {
			if($message->is_private){
				my $m = AnyEvent::XMPP::IM::Message->new(%$message, body => $message->content);
				$m->send( $account->connection );
			} else {
				my $room_name = $message->to;
				(my $group_message_content = $message->content) =~ s/$room_name\///;
				my $m = AnyEvent::XMPP::Ext::MUC::Message->new(%$message, body => $group_message_content, type => 'groupchat');
				if ( my $room = $self->_muc->get_room( $account->connection, $message->to) ) {
					$m->to($room->jid);
					$m->send($room);
				}
			}
		}
	}

	###########
	# INTERNAL
	###########

	method privmsg ( $to, $message ) {
		$self->handle->send_srv(
			'PRIVMSG' => $to,
			encode_utf8($message),
		);
		return;
	}

	# Event: Connected to server
	method cb_client_session_ready ( $client, $acc ) {
		$self->me( $acc->jid );
		for my $room ( @{ $self->channels } ) {
			$self->_muc->join_room(
				$acc->connection, join('@', $room, $self->my_config->{conference_server}),
				node_jid( $acc->jid ),
				history          => { chars => 0 },
				nickcollision_cb => sub {
					my $tried = shift;
					$tried .= '1' if $tried !~ m/\d$/;
					return ++$tried;
				}
			);
		}                                                         

		return;
	}

	method cb_client_contact_request_subscribe ($cl, $acc, $roster, $contact) {
		$contact->send_subscribed;
		return;
	}

	method cb_client_error ($cl, $acc, $error) {
		warn "Error encountered: " . $error->string . "\n";
		return;
	}

	# Event: Disconnected from server
	method cb_client_disconnect ( $client, ... ) {
		unless ( $self->force_disconnect ) {
			$self->notify( 'X', 'Disconnected, attempting to reconnect...');
			sleep(3);
			$client->start
		}
		return;
	}

	# Event: User joined channel
	method cb_muc_join( $muc, $cl, $room, $user ) {
		return if ($user eq $self->me);
		$self->event_user_enter( $room, $user );
		return;
	}

	# Event: Received a message
	method cb_muc_message( $client, $room, $msg, $is_echo ) {
		return if $is_echo;
		return if !defined $msg->from_nick;
		my $me = $room->get_me->nick;
		$self->event_message(
			$self->get_new_message(
				{
					from    => $msg->from,
					from_nick => res_jid($msg->from),
					to      => $msg->room->jid,
					to_nick => node_jid( $msg->from ),
					content => $msg->any_body,
					me => $msg->room->get_me->nick,
				}
			)
		);
		return;
	}

	method cb_client_message( $client, $acc, $msg ) {
		return if !$msg->any_body;
		$self->event_message(
			$self->get_new_message({
				from => $msg->from,
				from_nick => node_jid($msg->from),
				to => $msg->to,
				to_nick => node_jid($msg->to),
				content => $msg->any_body
			})
		);
		return;
	}

	# Event: User left a channel
	method cb_muc_part( $muc, $client, $room, $user ) {
		return if ($user eq $self->me);
		$self->event_user_leave( $room, $user );
	}

}

1;

