###########################################################################
# whatbot/Component.pm
###########################################################################
# base class for all whatbot components. add this to each component of
# whatbot to give base functionality.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Component;
use Moose;

has 'parent'     => ( is => 'rw' );
has 'config'     => ( is => 'rw' );
has 'store'      => ( is => 'rw' );
has 'connection' => ( is => 'rw' );
has 'log'        => ( is => 'rw' );
has 'controller' => ( is => 'rw' );
has 'timer'      => ( is => 'rw' );
has 'models'     => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

sub BUILD {
	my ( $self, $params ) = @_;
	
	if ( $params->{'base_component'} ) {
		$self->parent( $params->{'base_component'}->parent );
		$self->config( $params->{'base_component'}->config );
		$self->store( $params->{'base_component'}->store );
		$self->connection( $params->{'base_component'}->connection );
		$self->log( $params->{'base_component'}->log );
		$self->controller( $params->{'base_component'}->controller );
		$self->timer( $params->{'base_component'}->timer );
		$self->models( $params->{'base_component'}->models );
		
		unless ( ref($self) =~ /Message/ or ref($self) =~ /Command::/ or ref($self) =~ /::Table/ ) {
			$self->log->write(ref($self) . ' loaded.') ;
		}
	}
}

sub model {
    my ( $self, $model_name ) = @_;
    
    return $self->models->{ lc($model_name) } if ( $self->models->{ lc($model_name) } );
    warn ref($self) . ' tried to reference model "' . $model_name . '" even though it does not exist.';
    return;
}

1;

=pod

=head1 NAME

whatbot::Component - Base component for all whatbot modules.

=head1 SYNOPSIS

 use Moose;
 extends 'whatbot::Component';
 
 $self->log('I am so awesome.');

=head1 DESCRIPTION

whatbot::Component is the base component for all whatbot modules. This requires
a little bit of magic from the caller, as the accessors all need to be filled
by whatbot::Controller, or the calling method needs to pass 'base_component'
to the Component subclass to fill the proper accessors.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
