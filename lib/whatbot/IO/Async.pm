###########################################################################
# whatbot/IO/Async.pm
###########################################################################
#
# LWP Async functionality for whatbot
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::IO::Async extends whatbot::IO {
    use whatbot::IO::Async::Hack;
    use HTTP::Async;
    use HTTP::Cookies;
    use HTTP::Request;

    has 'tracker'    => ( is => 'ro', isa => 'HashRef', default => sub {{}} );
    has 'async'      => ( is => 'ro', isa => 'HTTP::Async', lazy_build => 1 );
    has 'cookie_jar' => ( is => 'ro', isa => 'HTTP::Cookies', lazy_build => 1 );
    sub _build_async { return HTTP::Async->new() }
    sub _build_cookie_jar { return HTTP::Cookies->new() }

    method BUILD ($) {
        $self->name('Async');
        $self->me( $self->name );
    }

    method event_loop() {
        if ( $self->async->not_empty ) {
            my ( $response, $id ) = $self->async->next_response;
            return unless ($response);
            
            $self->cookie_jar->extract_cookies($response);
            $self->tracker->{$id}->[0]->( $self->tracker->{$id}->[1], $response, @{ $self->tracker->{$id}->[2] } );
        }
    }

    method enqueue ( $caller_object, $req, $callback, ArrayRef $params? ) {
        $self->cookie_jar->add_cookie_header($req);
        $req->user_agent('whatbot/1.0') unless ( $req->user_agent );
        my $id = $self->async->add($req);
        return unless ($id);
        $self->tracker->{$id} = [ $callback, $caller_object, $params ];
        return $id;
    }
}

1;

=pod

=head1 NAME

whatbot::IO::Async - LWP Async functionality for whatbot.

=head1 SYNOPSIS

 sub foo {
     my ( $self, $message ) = @_;
     
     my $medium = $message->origin;
     $self->async->enqueue(
         HTTP::Request->new( GET => 'http://www.google.com' ),
         \&callback
     );
 }

 sub callback {
     my ( $self, $response ) = @_;
     
     return 'Success!' if ( $response->is_success );
 }

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::IO

=over 4

=item whatbot::IO::Timer

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
