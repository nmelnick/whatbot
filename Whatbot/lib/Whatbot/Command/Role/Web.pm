###########################################################################
# Web.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

Whatbot::Command::Role::Web - Provide web endpoints for your Command

=head1 SYNOPSIS

 package Whatbot::Command::Example;
 use Moose;
 BEGIN { extends 'Whatbot::Command'; with 'Whatbot::Command::Role::Web'; }
 
 sub register {
	 my ($self) = @_;
	 
	 $self->require_direct(0);
	 $self->web( '/example', \&example );
 }

 sub example {
	 my ( $self, $httpd, $req ) = @_;

	 my $id = $req->parm('id');
	 $req->respond( 'content' => [ 'text/html', $out ] );
	 return;
 }

=head1 DESCRIPTION

Whatbot::Command::Role::Web provides the ability to define web endpoints in your
Command. To do this, one or more endpoints must be defined in the register()
method of your command, that correspond to subroutines in the class.

A subroutine that responds to an endpoint expects three arguments: $self, which
is your Command instance, $httpd, which is the L<AnyEvent::HTTPD> object that
answered the request, and $req, which is the request as a
L<AnyEvent::HTTPD::Request>.

For easier responses, you may also want to check out
L<Whatbot::Command::Role::Template> and L<Whatbot::Command::Role::BootstrapTemplate>.

=head1 PUBLIC METHODS

=over 4

=cut

role Whatbot::Command::Role::Web {
	requires 'register';

=item web( $path, \&callback )

Set up a web endpoint, used within the register() function. The first parameter
is a path to respond to after the hostname and port of the request. Note that
the first path registered wins, so choose your paths carefully. The second
parameter is a callback when a request is received. Three parameters are sent to
the callback: $self, which is your command's instance, $httpd, which is an
L<AnyEvent::HTTPD> object, and $req, which is a L<AnyEvent::HTTPD::Request>
object.

=cut

	method web( $path, $callback ) {
		return unless ( $self->ios->{Web} );
		return $self->ios->{Web}->add_dispatch( $self, $path, $callback );
	}

=item web_url()

Returns the URL that the web server is currently responding to.

=cut

	method web_url() {
		return unless ( $self->ios->{Web} );
		return sprintf( '%s:%d', $self->ios->{Web}->my_config->{url}, $self->ios->{Web}->my_config->{port} );
	}

}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
