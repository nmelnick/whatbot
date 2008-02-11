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

has 'parent' => (
	is	=> 'rw'
);

has 'config' => (
	is	=> 'rw'
);

has 'store' => (
	is	=> 'rw'
);

has 'log' => (
	is	=> 'rw'
);

has 'controller' => (
	is	=> 'rw'
);

sub BUILD {
	my ($self, $params) = @_;
	
	if ($params->{baseComponent}) {
		$self->parent($params->{baseComponent}->parent);
		$self->config($params->{baseComponent}->config);
		$self->store($params->{baseComponent}->store);
		$self->log($params->{baseComponent}->log);
		$self->controller($params->{baseComponent}->controller);
		
		unless (ref($self) =~ /Message/ or ref($self) =~ /Command::/) {
			$self->log->write(ref($self) . " loaded.") ;
		}
	}
}

1;