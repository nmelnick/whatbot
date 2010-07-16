###########################################################################
# whatbot/Component/Base.pm
###########################################################################
# base class for whatbot::component.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::Component::Base {
	has 'parent'         => ( is => 'rw', isa => 'whatbot' );
	has 'config'         => ( is => 'rw', isa => 'whatbot::Config' );
	has 'ios'            => ( is => 'rw', isa => 'HashRef' );
	has 'database'       => ( is => 'rw', isa => 'whatbot::Database' );
	has 'log'            => ( is => 'rw', isa => 'whatbot::Log' );
	has 'controller'     => ( is => 'rw', isa => 'whatbot::Controller' );
	has 'timer'          => ( is => 'rw', isa => 'whatbot::Timer' );
	has 'models'         => ( is => 'rw', isa => 'HashRef' );
	has 'store'          => ( is => 'rw', isa => 'whatbot::Store' ); # deprecated
}

1;
