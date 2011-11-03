###########################################################################
# whatbot/Command/Calendar.pm
###########################################################################
# Displays system time and date
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Calendar;
use Moose;
BEGIN { extends 'whatbot::Command'; }
use namespace::autoclean;

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub day : GlobalRegEx('what day is .*?today') : Command {
    my ( $self, $message ) = @_;
    
    my ( $second, $minute, $hour, $day, $month, $year ) = $self->get_localtime();
    return "The date is " . sprintf("%d/%02d/%02d", $year, $month, $day) . ".";
}

sub time : GlobalRegEx('what time is it') : Command {
    my ( $self, $message ) = @_;
    
    my ( $second, $minute, $hour, $day, $month, $year ) = $self->get_localtime();
	return "The time is " . sprintf("%02d:%02d:%02d", $hour, $minute, $second) . ".";
}

sub get_localtime {
    my ( $self ) = @_;
    
    my ( $second, $minute, $hour, $day, $month, $year ) = localtime(CORE::time);
	$year += 1900;
	$month++;
	return ( $second, $minute, $hour, $day, $month, $year );
}

__PACKAGE__->meta->make_immutable;

1;