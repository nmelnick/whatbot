###########################################################################
# whatbot/IO/Log.pm
###########################################################################
#
# whatbot logfile connector
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::IO::Log::Infobot;
use Moose;
extends 'whatbot::IO::Log';
use whatbot::Message;

sub parseLine {
	my ($self, $line) = @_;
	
	if ($line =~ /^(\d+) \[\d+\] <(.*?)\/(.*?)> (.*)/) {
		my $date = $1;
		my $user = $2;
		my $channel = $3;
		my $message = $4;
		return if (!$user or $message =~ /^!/);
		
		$message =~ s/\\what/what/g;
		$message =~ s/\\is/is/g;
		
		my $messageObj = new whatbot::Message(
			from			=> $user,
			to				=> $channel,
			content			=> $message,
			timestamp		=> $date,
			me				=> $self->me,
			base_component	=> $self->parent->base_component
		);
		
		$self->event_message_public(
			$user,
			$messageObj
		);
	}
}

1;