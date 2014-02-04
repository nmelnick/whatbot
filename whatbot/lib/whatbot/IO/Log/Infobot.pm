###########################################################################
# whatbot/IO/Log/Infobot.pm
###########################################################################
# whatbot logfile connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::IO::Log::Infobot extends whatbot::IO::Log {
	use whatbot::Message;

	method parse_line( $line ) {
		if ( $line =~ /^(\d+) \[\d+\] <(.*?)\/(.*?)> (.*)/ ) {
			my $date = $1;
			my $user = $2;
			my $channel = $3;
			my $message_text = $4;
			return if ( !$user or $message_text =~ /^!/ );
		
			$message_text =~ s/\\what/what/g;
			$message_text =~ s/\\is/is/g;
		
			my $message = whatbot::Message->new(
				'from'			    => $user,
				'to'				=> $channel,
				'content'			=> $message_text,
				'timestamp'		    => $date,
				'me'				=> $self->me,
			);
		
			$self->event_message($message);
		}
	}
}

1;
