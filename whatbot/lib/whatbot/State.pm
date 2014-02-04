###########################################################################
# State.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::DeclareX plugins => [qw/ build singleton /];

=head1 NAME

whatbot::State - Singleton to track state

=head1 SYNOPSIS

 my $state = whatbot::State->instance;

=head1 PUBLIC ACCESSORS

=over 4

=item parent

The parent component of this module.

=item config

The L<whatbot::Config> instance.

=item ios

A HashRef of available L<whatbot::IO> instances.

=item log

The available L<whatbot::Log> instance, commonly used as $self->log->write('Foo');.

=back

=cut

class whatbot::State is singleton {
	has 'parent'     => ( is => 'rw', isa => 'whatbot' );
	has 'config'     => ( is => 'rw', isa => 'whatbot::Config' );
	has 'ios'        => ( is => 'rw', isa => 'HashRef' );
	has 'database'   => ( is => 'rw', isa => 'whatbot::Database' );
	has 'log'        => ( is => 'rw', isa => 'whatbot::Log' );
	has 'controller' => ( is => 'rw', isa => 'whatbot::Controller' );
	has 'models'     => ( is => 'rw', isa => 'HashRef' );
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
