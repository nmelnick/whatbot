###########################################################################
# whatbot/IO/Web.pm
###########################################################################
# whatbot Web connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::IO::Web extends whatbot::IO::Legacy {
	use whatbot::Message;

	has 'pid' => (
		'is'  => 'rw',
		'isa' => 'Int',
	);
	has 'server' => (
		'is' => 'rw'
	);

	method BUILD {
		my $name = 'Web';
		$name =~ s/ /_/g;
		$self->name('Web');
		$self->me('Web');

		$self->server( whatbot::IO::Web::Server->new( $self->my_config->{port} ) );
		$self->server->dispatch( {} );
	}

	after connect () {
		$self->pid( $self->server->background() );
		$self->log->write(
			sprintf(
				'HTTP server started on port %d, running on PID %d.',
				$self->my_config->{port},
				$self->pid,
			)
		);
		return;
	}

	method disconnect () {
		system( 'kill', $self->pid ) if ( $self->pid );
		return;
	}

	method event_loop () {
		return;
	}

	method add_dispatch ( $command, $path, $callback ) {
		$self->server->dispatch->{$path} = {
			'callback' => $callback,
			'command'  => $command,
		};
	}
}

class whatbot::IO::Web::Server extends HTTP::Server::Simple::CGI {
	has 'dispatch' => (
		'is'      => 'rw',
		'isa'     => 'HashRef',
	);
 
	method handle_request ($cgi) {
		my $path = $cgi->path_info();
		my $handler = $self->dispatch->{$path};

		if ( $handler and ref($handler) eq 'HASH' ) {
			print "HTTP/1.0 200 OK\r\n";
			$handler->{callback}->( $handler->{command}, $cgi );

		} else {
			print "HTTP/1.0 404 Not found\r\n";
			print $cgi->header,
			$cgi->start_html('Not found'),
			$cgi->h1('Not found'),
			$cgi->end_html;
		}
	}

	__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
}

1;
