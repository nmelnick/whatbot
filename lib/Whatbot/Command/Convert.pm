###########################################################################
# Whatbot/Command/Convert.pm
###########################################################################
# convert units
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Convert;
use Moose;
use Whatbot::Command;
BEGIN { extends 'Whatbot::Command' }

use Math::Units;
use namespace::autoclean;

sub register {
	my ($self) = @_;

	$self->command_priority('Extension');
	$self->require_direct(0);
	
	return;
}

sub do_convert : CommandRegEx('([\-\d\.,]+) ?(.*) to (.*)')  {
	my ( $self, $message, $captures ) = @_;

	return unless ( $captures and @$captures );
	my ( $unit, $from, $to ) = @$captures;
	my $unit_from = $from;
	$unit_from =~ s/res?$/er/;
	my $unit_to = $to;
	$unit_to =~ s/res?$/er/;
	my $result = eval {
		Math::Units::convert( $unit, $unit_from, $unit_to );
	};
	if ($@) {
		warn $@;
		return 'I cannot convert from ' . $from . ' to ' . $to . '.';
	}
	unless (defined $result) {
		return 'For some reason, I could not convert ' . $unit . ' from ' . $from . ' to ' . $to . '.';
	}

	return $message->from . ', should be ' . $result . ' ' . $to . '.';
}

__PACKAGE__->meta->make_immutable;

1;
