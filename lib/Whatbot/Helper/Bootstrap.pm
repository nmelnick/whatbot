###########################################################################
# Bootstrap.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

our $VERSION = '0.1';

=head1 NAME

Whatbot::Helper::Bootstrap - Provide a helper shell to render a Bootstrap page.

=head1 DESCRIPTION

This module will allow a command to utilize Twitter Bootstrap 3 as the default
layout for their web command. There isn't a lot of customization provided, this
is just a way to quickly get something running in whatbot. It provides a global
menu to hop to other web applications, and can have additional nav options added
on deployment.

The majority of the work is handled in L<Whatbot::Command::Role::BootstrapTemplate>.
The only available method here is add_application(), which will add your command
to the global menu.

=head1 SYNOPSIS

 package Whatbot::Command::Example;
 use Moose;
 BEGIN { extends 'Whatbot::Command'; with 'Whatbot::Command::Role::BootstrapTemplate'; }
 
 sub register {
     my ($self) = @_;
     
     $self->require_direct(0);

     # Add command to global menu
     Whatbot::Helper::Bootstrap->add_application( 'Example', '/example' );

     # Add an additional menu option, if desired	 
     $self->add_menu_item( Whatbot::Helper::Bootstrap::Link->new({
         'title' => 'A fun trick',
         'href'  => '/example/fun',
     }) );

     $self->web( '/example', \&example );
     $self->web( '/example/fun', \&example_fun );
     return;
 }

=head1 PUBLIC METHODS

=over 4

=cut

BEGIN {
	$Whatbot::Helper::Bootstrap::VERSION = '0.12';
	@Whatbot::Helper::Bootstrap::applications = ();
}

class Whatbot::Helper::Bootstrap {


=item add_application( $name, $path )

Add an application to the global menu.

=cut

	method add_application( Str $name, Str $path ) {
		foreach ( @Whatbot::Helper::Bootstrap::applications ) {
			return if ( $_->[0] eq $name );
		}
		push( @Whatbot::Helper::Bootstrap::applications, [ $name, $path ] );
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
