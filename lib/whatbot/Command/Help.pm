###########################################################################
# whatbot/Command/Help.pm
###########################################################################
# DEFAULT: Grabs help for a given command
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Help;
use Moose;
BEGIN { extends 'whatbot::Command' }

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Primary');
	$self->require_direct(1);
}

sub parse_message : CommandRegEx('(.*)') {
	my ( $self, $message, $captures ) = @_;
    
    if ( $captures and $captures->[0] ) {
        if ( defined $self->controller->command_short_name->{$captures->[0]} ) {
            return $self->controller->command_short_name->{$captures->[0]}->help();
        } else {	            
	        return
	            'No such command: "' . $1 . '". ' . $self->available();
        }
    } else {
        return
            'Whatbot is a modular, extensible, buzzword-compliant chat bot ' .
            'written in Perl and tears. ' . $self->available();
    }
    
    return undef;
}

sub available {
    my ( $self ) = @_;
    
    return 'Help is available for: ' .
        join('', map {
            if ($_ and $_ ne 'help') {
                if ($self->controller->command_short_name->{$_}->help() =~ /Help is not/) {
                    '';
                } else {
                    $_ . ' ';
                }
            }
        } keys %{$self->controller->command_short_name} );
}
1;
