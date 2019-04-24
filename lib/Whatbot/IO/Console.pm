###########################################################################
# Whatbot/IO/Console.pm
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::IO::Console extends Whatbot::IO {
    use AnyEvent::ReadLine::Gnu;
	use Encode;

	has 'handle' => (
		is  => 'rw',
		isa => 'Maybe[AnyEvent::ReadLine::Gnu]',
	);

	method BUILD (...) {
		my $name = 'Console';
        my $nick = ( $self->my_config->{'nick'} or 'whatbot' );
		$self->name($name);
		$self->me($nick);
	}

	after connect {
		my $config = $self->my_config;
        $self->log->write('Console active');
        my $rl = AnyEvent::ReadLine::Gnu->new(
            prompt => '',
            on_line => sub { $self->console_message(@_); },
        );
        $self->handle($rl);
	}

	method disconnect () {
	}

	# Send a message
	method deliver_message ( $message ) {
        my $content = $message->content;
        my $line = sprintf( '[%s] <%s> %s', $message->to, $self->me, $content );
        AnyEvent::ReadLine::Gnu->print("$line\n");
	}

	# Event: Received a message
	method console_message( $message, $point? ) {
		$self->event_message(
			$self->get_new_message({
				'from'    => 'console',
				'to'      => 'console',
				'content' => $message,
			})
		);
		return;
	}
}

1;
