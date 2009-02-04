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
has 'log'        => ( is => 'rw' );
has 'controller' => ( is => 'rw' );
has 'timer'      => ( is => 'rw' );

sub BUILD {
	my ($self, $params) = @_;
	
	if ( $params->{'base_component'} ) {
		$self->parent( $params->{'base_component'}->parent );
		$self->config( $params->{'base_component'}->config );
		$self->store( $params->{'base_component'}->store );
		$self->log( $params->{'base_component'}->log );
		$self->controller( $params->{'base_component'}->controller );
		$self->timer( $params->{'base_component'}->timer );
		
		unless ( ref($self) =~ /Message/ or ref($self) =~ /Command::/ ) {
			$self->log->write(ref($self) . ' loaded.') ;
		}
	}
}

1;