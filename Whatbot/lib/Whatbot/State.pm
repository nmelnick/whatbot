###########################################################################
# State.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::State - Singleton to track state

=head1 SYNOPSIS

 my $state = Whatbot::State->instance;

=head1 PUBLIC ACCESSORS

=over 4

=item parent

The parent component of this module.

=item config

The L<Whatbot::Config> instance.

=item ios

A HashRef of available L<Whatbot::IO> instances.

=item log

The available L<Whatbot::Log> instance, commonly used as $self->log->write('Foo');.

=back

=cut

class Whatbot::State {
	has 'parent'     => ( is => 'rw', isa => 'Whatbot' );
	has 'config'     => ( is => 'rw', isa => 'Whatbot::Config' );
	has 'ios'        => ( is => 'rw', isa => 'HashRef' );
	has 'database'   => ( is => 'rw', isa => 'Whatbot::Database' );
	has 'log'        => ( is => 'rw', isa => 'Whatbot::Log' );
	has 'controller' => ( is => 'rw', isa => 'Whatbot::Controller' );
	has 'models'     => ( is => 'rw', isa => 'HashRef' );

	sub initialize {
		my ( $class, $ref ) = @_;
		no strict 'refs';
		${'Whatbot::State::singleton'} = Whatbot::State->new($ref);
	}

	sub instance {
		no strict 'refs';
		unless ( defined ${'Whatbot::State::singleton'} ) {
			shift->initialize();
		}
		return ${'Whatbot::State::singleton'};
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
