###########################################################################
# whatbot/Command/Calendar.pm
###########################################################################
# Displays system time and date
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Calendar;
use Moose;
extends 'whatbot::Command';

sub register {
	my ($self) = @_;
	
	$self->command_priority("Extension");
	$self->listen_for([
		qr/what time is it/,
		qr/what day is .*?today/
	]);
	$self->require_direct(0);
}

sub parse_message {
	my ($self, $messageRef) = @_;
	
	my ($second, $minute, $hour, $day, $month, $year) = localtime(time);
	$year += 1900;
	$month++;
	if ($messageRef->content =~ /time/) {
		return "The time is " . sprintf("%02d:%02d:%02d", $hour, $minute, $second) . ".";
	}
	if ($messageRef->content =~ /day/) {
		return "The date is " . sprintf("%d/%02d/%02d", $year, $month, $day) . ".";
	}
	return undef;
}

1;