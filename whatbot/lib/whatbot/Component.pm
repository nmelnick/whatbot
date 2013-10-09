###########################################################################
# whatbot/Component.pm
###########################################################################
# base class for all whatbot components. add this to each component of
# whatbot to give base functionality.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::Component {
    use whatbot::Component::Base;

    has 'base_component' => (
        is => 'rw',
        isa => 'whatbot::Component::Base',
        default => sub { whatbot::Component::Base->new() },
        handles => [qw(
            parent
            config
            ios
            database
            log
            controller
            models
        )]
    );

    method BUILD(...) {
    	unless ( ref($self) =~ /Message/ or ref($self) =~ /Command::/ or ref($self) =~ /::Table/ ) {
    		$self->log->write(ref($self) . ' loaded.') ;
    	}
    }

    method model ( Str $model_name ) {
        return $self->models->{ lc($model_name) } if ( $self->models->{ lc($model_name) } );
        warn ref($self) . ' tried to reference model "' . $model_name . '" even though it does not exist.';
        return;
    }

    method search_ios ( Str $io_search ) {
        foreach my $io ( keys %{ $self->ios } ) {
            if ( $io =~ /$io_search/ ) {
                return $self->ios->{$io};
            }
        }
        return;
    }

    method dispatch_message ( Str $io_path, $message ) {
        my ( $io_search, $target ) = split( /\:/, $io_path );
        my $io = $self->search_ios($io_search);
        unless ($io) {
            $self->log->write( 'IO could not be found for "' . $io_search . '".' );
            return;
        }
        $message->to($target) if ($target);
        return $io->event_message($message);
    }

    method send_message ( Str $io_path, $message ) {
        my ( $io_search, $target ) = split( /\:/, $io_path );
        if ( ( not $target ) and $io_search =~ /^#/ ) {
            $target = $io_search;
            $io_search = 'IRC';
        }
        my $io = $self->search_ios($io_search);
        unless ($io) {
            $self->log->write( 'IO could not be found for "' . $io_search . '".' );
            return;
        }
        $message->from( $io->me );
        $message->to($target) if ($target);
        return $io->send_message($message);
    }
}

1;

=pod

=head1 NAME

whatbot::Component - Base component for all whatbot modules.

=head1 SYNOPSIS

 use Moose;
 extends 'whatbot::Component';
 
 $self->log->write('I am so awesome.');

=head1 DESCRIPTION

whatbot::Component is the base component for all whatbot modules. This requires
a little bit of magic from the caller, as the accessors all need to be filled
by whatbot::Controller, or the calling method needs to pass 'base_component'
to the Component subclass to fill the proper accessors.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
