###########################################################################
# whatbot/IO/AIM.pm
###########################################################################
#
# whatbot AIM connector
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::IO::AIM;
use Moose;
extends 'whatbot::IO';
use HTML::Strip;

use Net::OSCAR qw(:standard);

has 'aimHandle' => (
	is	=> 'rw'
);
has 'strip' => (
	is		=> 'ro',
	default => sub { HTML::Strip->new() }
);

sub BUILD {
	my ($self) = @_;
	
	my $name = "AIM_" . $self->my_config->{screenname};
	$name =~ s/ /_/g;
	$self->name($name);
	$self->me($self->my_config->{screenname});
}

sub connect {
	my ($self) = @_;
	
	# Create Object
	my $oscar = Net::OSCAR->new();
	
	# Set callbacks
	$oscar->set_callback_im_in(\&cbMessage);
	$oscar->set_callback_signon_done(\&cbConnected);
	$oscar->set_callback_error(\&cbError);
	
	# Sign on
	$oscar->signon($self->my_config->{screenname}, $self->my_config->{password});
	$oscar->{_whatbot} = $self;
	$self->aimHandle($oscar);
	$self->aimHandle->do_one_loop();
}

sub disconnect {
	my ($self) = @_;
	
	$self->aimHandle->signoff();
}

sub event_loop {
	my ($self) = @_;
	
	$self->aimHandle->do_one_loop();
}

# Send a message
sub send_message {
	my ($self, $messageObj) = @_;
	
	# We're going to try and be smart.
	my $charactersPerLine = "1024";
	if (defined($self->my_config->{charactersperline}) 
	    and ref($self->my_config->{charactersperline}) ne 'HASH') {
		$charactersPerLine = $self->my_config->{charactersperline};
	}
	my @lines;
	my @messageWords = split(/\s/, $messageObj->content);
	
	# If any of the words are over our maxlength, then let Net::IRC split it.
	# Otherwise, it's probably actual conversation, so we should split words.
	my $line = "";
	foreach my $word (@messageWords) {
		if (length($word) > $charactersPerLine) {
			my $msg = $messageObj->content;
			$line = "";
			@lines = ();
			while (length($msg) > 0) {
				push(@lines, substr($msg, 0, $charactersPerLine));
				$msg = substr($msg, $charactersPerLine);
			}
			@messageWords = undef;
		} else {
			if (length($line) + length($word) + 1 > $charactersPerLine) {
				push(@lines, $line);
				$line = "";
			}
			$line .= " " if ($line);
			$line .= $word;
		}
	}
	# Close out
	push(@lines, $line) if ($line);
	
	# Send messages
	foreach my $outLine (@lines) {
		my $result = $self->aimHandle->send_im($messageObj->to, $outLine);
		if ($result > 0) {
			$self->eventMessagePrivate($self->me, $outLine);
		} else {
			$self->notify("Message could not be sent");
		}
		
	}
}

#
# INTERNAL
#

# Event: Received a message
sub cbMessage {
	my ($self, $from, $message, $isAwayResponse) = @_;
	
	$message = $self->{_whatbot}->strip->parse($message);
	$message =~ s/^[^A-z0-9]+//;
	$message =~ s/[\s]+$//;
	$self->{_whatbot}->eventMessagePrivate(
		$$from,
		$message,
		1
	) if (!$isAwayResponse);
}

sub cbConnected {
	my ($self) = @_;
	
	$self->{_whatbot}->notify("Connected successfully.");
}

sub cbError {
	my ($self, $connection, $error, $description, $fatal);

}

1;