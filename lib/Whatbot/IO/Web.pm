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
  has 'routes' => (
    'is'  => 'ro',
    'isa' => 'HashRef',
    'default' => sub { {} },
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
        'request_timeout' => 15,
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
    $self->server->reg_cb(
      request => sub {
        my ( $httpd, $req ) = @_;
        my $url = $req->url;
        $url =~ s/\?.*//;
        foreach my $path ( sort { $b cmp $a } keys %{ $self->routes } ) {
          my $info = $self->routes->{$path};
          if ( $url =~ /^$path$/ ) {
            eval {
              $req->respond( $info->{'callback'}->( $info->{'command'}, $httpd, $req ) );
            };
            if ($@) {
              $req->respond([ 500, 'internal server error', { 'Content-Type' => 'text/plain' }, 'internal server error' ]);
              $self->log_response( 500, $req, $path );
            } else {
              $self->log_response( 200, $req, $path );
            }
            $httpd->stop_request();
            return;
          }
        }
        $req->respond([ 404, 'not found', { 'Content-Type' => 'text/plain' }, 'not found' ]);
        $self->log_response( 404, $req );
        $httpd->stop_request();
        return;
      }
    );
    return;
  }

  method log_response( $code, $req, $path? ) {
    $self->log->write( sprintf( '(Web) %s %d %s %s [%s]', $req->client_host, $code, $req->method, $req->url, ( $path or 'none' ) ) );
  }

  method disconnect() {
    $self->server(undef);
    return;
  }

  method event_loop() {
    return;
  }

  method add_dispatch( $command, $path, $callback ) {
    $self->routes->{$path} = {
      'command'  => $command,
      'callback' => $callback,
    };
  }
}

1;
