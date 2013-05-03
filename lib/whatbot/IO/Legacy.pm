###########################################################################
# whatbot/IO/Legacy.pm
###########################################################################
#
# Legacy IO module
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::IO::Legacy extends whatbot::IO {
	has 'instance' => (
		is => 'rw',
	);

	method connect () {
		my $timer = AnyEvent->timer(
			'after'    => 1,
			'interval' => 1,
			'cb'       => sub {
				$self->event_loop(),
			},
		);
		$self->instance($timer);
		return;
	}
}

1;

=pod

=head1 NAME

whatbot::IO::Legacy - Use legacy IO modules with AnyEvent.

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::IO

=over 4

=item whatbot::IO::Legacy

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
