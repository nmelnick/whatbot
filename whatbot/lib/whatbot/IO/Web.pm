###########################################################################
# whatbot/IO/Web.pm
###########################################################################
# whatbot Web connector
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::IO::Web extends whatbot::IO {
	use whatbot::Message;
	use AnyEvent::HTTPD;

	has 'server' => (
		'is'  => 'rw',
		'isa' => 'AnyEvent::HTTPD',
	);

	method BUILD(...) {
		my $name = 'Web';
		$name =~ s/ /_/g;
		$self->name('Web');
		$self->me('Web');

		$self->my_config->{'url'} ||= 'http://' . `hostname`;
		chomp( $self->my_config->{'url'} );

		my $httpd = $self->server(
			AnyEvent::HTTPD->new(
				'port'            => $self->my_config->{port},
				'request_timeout' => 30,
			)
		);
	}

	after connect () {
		$self->log->write(
			sprintf(
				'HTTP server started on port %d.',
				$self->my_config->{'port'},
			)
		);
		return;
	}

	method disconnect () {
		$self->server(undef);
		return;
	}

	method event_loop () {
		return;
	}

	method add_dispatch ( $command, $path, $callback ) {
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
