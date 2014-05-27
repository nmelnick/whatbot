###########################################################################
# Component.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Component - Base component for all whatbot modules.

=head1 SYNOPSIS

 use MooseX::Declare;
 use Method::Signatures::Modifiers;

 class whatbot::Command extends whatbot::Component {
    method foo() {
       $self->log->write('I am so awesome.');
    }
 }

=head1 DESCRIPTION

whatbot::Component is the base component for all whatbot modules. This requires
a little bit of magic from the caller, as the accessors all need to be filled
by whatbot::Controller.

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

=head1 PUBLIC METHODS

=over 4

=cut

class whatbot::Component {
    use whatbot::State;

    method BUILD(...) {
    	unless ( ref($self) =~ /Message/ or ref($self) =~ /Command::/ or ref($self) =~ /::Table/ ) {
    		$self->log->write(ref($self) . ' loaded.') ;
    	}
    }

    sub state {
        return whatbot::State->instance();
    }

    sub parent {
        return state()->parent;
    }

    sub config {
        return state()->config;
    }

    sub ios {
        return state()->ios;
    }

    sub database {
        return state()->database;
    }

    sub log {
        return state()->log;
    }

    sub controller {
        return state()->controller;
    }

    sub models {
        return state()->models;
    }

=item model($model_name)

Retrieve the model (or whatbot::Database::Table::*) instance associated with the
provided name. For example, to retrieve the active instance of
L<whatbot::Database::Table::Factoid>, call $self->model('Factoid'). This will
warn and return nothing if the model is not found.

=cut

    method model ( Str $model_name ) {
        return $self->models->{ lc($model_name) } if ( $self->models->{ lc($model_name) } );
        warn ref($self) . ' tried to reference model "' . $model_name . '" even though it does not exist.';
        return;
    }

=item search_ios($search_string)

Retrieve the IO with a partial match to the given string. This is handy for
getting the reference to an IO that may have an odd name, like IRC_127.0.0.1.

=cut

    method search_ios ( Str $io_search ) {
        foreach my $io ( keys %{ $self->ios } ) {
            if ( $io =~ /$io_search/ ) {
                return $self->ios->{$io};
            }
        }
        return;
    }

=item dispatch_message( $io_path, $message )

Dispatch a L<whatbot::Message>, corresponding to the given IO path, through
the command dispatcher.

=cut

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

=item dispatch_message( $io_path, $message )

Send a L<whatbot::Message> via the given IO name or partial IO name.

=cut

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

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
