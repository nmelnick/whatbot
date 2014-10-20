###########################################################################
# Whatbot/IO/Legacy.pm
###########################################################################
#
# Legacy IO module
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class Whatbot::IO::Legacy extends Whatbot::IO {
	has 'instance' => (
		is => 'rw',
	);

	method connect() {
		my $timer = AnyEvent->timer(
			'after'    => 3,
			'interval' => 5,
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

Whatbot::IO::Legacy - Use legacy IO modules with AnyEvent.

=head1 INHERITANCE

=over 4

=item Whatbot::Component

=over 4

=item Whatbot::IO

=over 4

=item Whatbot::IO::Legacy

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
