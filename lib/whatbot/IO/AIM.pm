###########################################################################
# whatbot/IO/AIM.pm
###########################################################################
# whatbot AIM connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::IO::AIM;
use Moose;
extends 'whatbot::IO';

use HTML::Strip;

use Net::OSCAR qw(:standard);

has 'aim_handle' => ( is => 'rw' );
has 'strip'      => ( is => 'ro', default => sub { HTML::Strip->new() } );

sub BUILD {
	my ( $self ) = @_;
	
	my $name = 'AIM_' . $self->my_config->{'screenname'};
	$name =~ s/ /_/g;
	$self->name($name);
	$self->me( $self->my_config->{'screenname'} );
}

sub connect {
	my ( $self ) = @_;
	
	# Create Object
	my $oscar = Net::OSCAR->new(
	);
	
	# Set callbacks
	$oscar->set_callback_im_in(\&cb_message);
	$oscar->set_callback_signon_done(\&cb_connected);
	$oscar->set_callback_error(\&cb_error);
	
	# Sign on
	$oscar->signon(
	    $self->my_config->{'screenname'},
	    $self->my_config->{'password'}
	);
	$oscar->{'_whatbot'} = $self;
	$self->aim_handle($oscar);
	$self->aim_handle->do_one_loop();
}

sub disconnect {
	my ($self) = @_;
	
	$self->aim_handle->signoff();
}

sub event_loop {
	my ($self) = @_;
	
	eval {
	    $self->aim_handle->do_one_loop();
    };
}

# Send a message
sub send_message {
	my ($self, $message) = @_;
	
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
			$self->event_message_private( $self->me, $out_line );
		} else {
			$self->notify('Message could not be sent');
		}
		
	}
}

#
# INTERNAL
#

# Event: Received a message
sub cb_message {
	my ( $self, $from, $message, $isAwayResponse ) = @_;
	
	$message = $self->{'_whatbot'}->strip->parse($message);
	$message =~ s/^[^A-z0-9]+//;
	$message =~ s/[\s]+$//;
	$self->{'_whatbot'}->event_message_private(
		$$from,
		$message,
		1
	) if ( !$isAwayResponse );
}

sub cb_connected {
	my ( $self ) = @_;
	
	$self->{'_whatbot'}->notify('Connected successfully.');
}

sub cb_error {
	my ( $self, $connection, $error, $description, $fatal );
    
    $self->{'_whatbot'}->notify($error);
}

1;