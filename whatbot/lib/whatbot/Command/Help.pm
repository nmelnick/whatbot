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
use namespace::autoclean;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Primary');
	$self->require_direct(1);
    return;
}

sub parse_message : GlobalRegEx('^help ?(.*)?') {
	my ( $self, $message, $captures ) = @_;
    
    if ( $captures and $captures->[0] ) {
        if ( defined $self->controller->command_short_name->{$captures->[0]} ) {
            my @replies;
            my $help = $self->controller->command_short_name->{$captures->[0]}->help();
            $help = [$help] unless ( ref($help) );
            foreach my $str ( @$help ) {
                my $reply = $message->reply({
                    to      => $message->reply_to || $message->from,
                    content => $str
                });
                push( @replies, $reply );
            }
            return \@replies;
        } else {
            return $message->reply({
                to      => $message->reply_to || $message->from,
                content => 'No such command: "' . $captures->[0] . '". ' . $self->available()
            });
        }
    } else {
        return
            'Whatbot is a modular, extensible, buzzword-compliant chat bot ' .
            'written in Perl and tears. ' . $self->available();
    }
    
    return;
}

sub available {
    my ( $self ) = @_;
    
    my @modules;
    map {
        if ( $_ and $_ ne 'help' ) {
            unless ($self->controller->command_short_name->{$_}->help() =~ /Help is not/) {
                push( @modules, $_ ) unless ( $_ =~ /^\s*$/ );
            }
        }
    } keys %{$self->controller->command_short_name};
    return 'Help is available for: ' . join( ', ', @modules );
}

__PACKAGE__->meta->make_immutable;

1;
