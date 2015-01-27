###########################################################################
# HipChat.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

BEGIN {
	$Whatbot::IO::HipChat::VERSION = '0.1';
}

class Whatbot::IO::HipChat extends Whatbot::IO::Jabber {
        use AnyEvent::XMPP::Util qw(res_jid);
	method BUILDARGS ( %arg_hash ) {
		my $args = \%arg_hash;
		die 'HipChat component requires a "username" and a "password".' unless (
			$args->{'my_config'}->{'username'}
			and $args->{'my_config'}->{'password'}
		);

		$args->{'my_config'}->{'host'} ||= 'chat.hipchat.com';
		$args->{'my_config'}->{'conference_server'} ||= 'conf.hipchat.com';
		$args->{'my_config'}->{'jabber_id'} = $args->{'my_config'}->{'username'} . '@' . $args->{'my_config'}->{'host'};
		$args->{'my_config'}->{'company'} = $args->{'my_config'}->{'username'};
		$args->{'my_config'}->{'company'} =~ s/_.*//;
		my @channels;
		my $rooms = $args->{'my_config'}->{'rooms'};
		$rooms = [$rooms] unless ( ref($rooms) );
		foreach my $room (@$rooms) {
			$room = $args->{'my_config'}->{'company'} . '_' . lc($room);
			$room =~ s/ /_/g;
			push( @channels, $room );
		}
		$args->{'my_config'}->{'channel'} = \@channels;
		return $args;
	}

	method BUILD(...) {
	        my $me = $self->{'my_config'}->{'nick'};
	        my $alias = $self->{'my_config'}->{'alias'} || "@".($me=~s/\s//gr);
	        $self->me( "($alias|$me)" );
	}

	# Event: Received a message
	method cb_muc_message( $client, $room, $msg, $is_echo ) {
		return if $is_echo;
		return if !defined $msg->from_nick;

		$self->event_message(
			$self->get_new_message(
				{
					reply_to => $msg->room->jid,
					from    => '@'.(res_jid($msg->from) =~ s/\s//gr),
					to      => $msg->room->jid,
					content => $msg->any_body
				}
			)
		);
		return;
	      }
	}

1;

=pod

=head1 NAME

Whatbot::IO::HipChat - Provide HipChat connection via XMPP.

=head1 CONFIG

	"io": [
		{
			"interface": "HipChat",
			"username" : "123456_0987654"
			"nick" : "What Bot",
			"password": "s0methingm4deup!",
			"rooms": [
				"Example Room"
			]
		}
	]

=over 4

=item host

(Optional) Hostname of the HipChat server, defaults to chat.hipchat.com.

=item port

(Optional) Port to connect to on the HipChat server. Defaults to 5222.

=item nick

Nickname to use in the channel, MUST match the "Real Name" as provided to
HipChat, as it is used to register to a HipChat room.

=item username 

The XMPP/Jabber username for your HipChat account, found in Profile > 
XMPP/Jabber info > Username.

=item password

Password to connect with.

=item presence_status

(Optional) Status to send for presence. This is a freetext status.

=item conference_server

(Optional) Conference server for MUC channels, defaults to conf.hipchat.com.

=item rooms

Room or array of rooms to join. They can be expressed as the full name, or the
XMPP/Jabber name of an existing room.

=item xmpp_debug

(Optional) Set to true to output debug XML output.

=back

=head1 DESCRIPTION

Whatbot::IO::Jabber connects to most Jabber/XMPP providers, and responds over
private messages or inside MUC/chat rooms.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
