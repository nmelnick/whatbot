###########################################################################
# whatbot/Command/Convert.pm
###########################################################################
# convert units
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Convert;
use Moose;
BEGIN { extends 'whatbot::Command' }

use Math::Units;

sub register {
	my ($self) = @_;

	$self->command_priority('Extension');
	$self->require_direct(0);
	
	return;
}

sub do_convert : CommandRegEx('(\d+) ?(.*) to (.*)')  {
	my ( $self, $message, $captures ) = @_;

	return unless ( $captures and @$captures );
	my ( $unit, $from, $to ) = @$captures;
	my $result = eval {
		Math::Units::convert( $unit, $from, $to );
	};
	if ($@) {
		return 'I cannot convert from ' . $from . ' to ' . $to . '.';
	}
	unless (defined $result) {
		return 'For some reason, I could not convert ' . $unit . ' from ' . $from . ' to ' . $to . '.';
	}

	return $message->from . ', should be ' . $result . ' ' . $to . '.';
}

1;
