###########################################################################
# Whatbot/IO/Web.pm
###########################################################################
# whatbot Web connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

class Whatbot::IO::Web extends Whatbot::IO {
	use Whatbot::Message;
	use AnyEvent::HTTPD;

	has 'server' => (
		'is'  => 'rw',
		'isa' => 'Maybe[AnyEvent::HTTPD]',
	);

	method BUILD(...) {
		my $name = 'Web';
		$name =~ s/ /_/g;
		$self->name('Web');
		$self->me('Web');

		$self->my_config->{'port'} ||= 2301;
		$self->my_config->{'url'} ||= 'http://' . `hostname` . ( $self->my_config->{'port'} == 80 ? '' : sprintf( ':%d', $self->my_config->{'port'} ) );
		chomp( $self->my_config->{'url'} );

		my $httpd = $self->server(
			AnyEvent::HTTPD->new(
				'port'            => $self->my_config->{'port'},
				'request_timeout' => 30,
			)
		);
	}

	after connect() {
		$self->log->write(
			sprintf(
				'HTTP server started on port %d.',
				$self->my_config->{'port'},
			)
		);
		return;
	}

	method disconnect() {
		$self->server(undef);
		return;
	}

	method event_loop() {
		return;
	}

	method add_dispatch( $command, $path, $callback ) {
		$self->server->reg_cb(
			$path => sub {
				my ( $httpd, $req ) = @_;

				my $response = $callback->( $command, $httpd, $req );
				$req->respond($response);
			}
		);
	}
}

1;
