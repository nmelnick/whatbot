###########################################################################
# whatbot/IO/AIM.pm
###########################################################################
# whatbot AIM connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

our $VERSION = '0.1';

class whatbot::IO::AIM extends whatbot::IO::Legacy {
	use HTML::Strip;
	use Net::OSCAR qw(:standard);
	use whatbot::Message;

	has 'aim_handle' => ( is => 'rw' );
	has 'strip'      => ( is => 'ro', default => sub { HTML::Strip->new() } );

	method BUILD {
		die 'AIM component requires a "screenname" and a "password"' unless (
			$self->my_config->{'screenname'}
			and $self->my_config->{'password'}
		);

		my $name = 'AIM_' . $self->my_config->{'screenname'};
		$name =~ s/ /_/g;
		$self->name($name);
		$self->me( $self->my_config->{'screenname'} );
	}

	after connect {
		# Create Object
		my $oscar = Net::OSCAR->new();
	
		# Set callbacks
		$oscar->set_callback_im_in(\&cb_message);
		$oscar->set_callback_signon_done(\&cb_connected);
		$oscar->set_callback_error(\&cb_error);
		$oscar->set_callback_snac_unknown( sub {} );
	
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
			my $result = $self->aim_handle->send_im( $message->to, $out_line );
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

	# Event: Received a message
	method cb_message( $from?, $message?, $is_away_response? ) {
		$message = $self->{'_whatbot'}->strip->parse($message);
		$message =~ s/^[^A-z0-9]+//;
		$message =~ s/[\s]+$//;
		$self->{'_whatbot'}->event_message( whatbot::Message->new({
			'from'    => $$from,
			'to'      => $self->me,
			'content' => $message,
		}) ) unless ( $is_away_response );
	}

	# Event: Connected
	method cb_connected {
		$self->{'_whatbot'}->notify( '', 'Connected successfully.' );
	}

	# Event: Error
	method cb_error( $connection, $error, $description, $fatal ) {
		$self->{'_whatbot'}->notify($error);
	}
}

1;

=pod

=head1 NAME

whatbot::IO::AIM - Provide chat through AOL Instant Messenger.

=head1 CONFIG

 "io" : {
     "AIM" : {
         "screenname" : "myaimscreenname",
         "password" : "myaimpassword"
     }
 }

=head1 DESCRIPTION

whatbot::IO::AIM provides a connection interface to AIM/AOL Instant Messenger.
It only supports private chats, and not AOL chat rooms.

This uses whatbot::IO::Legacy, as Net::OSCAR does not fit within any existing
event models.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
