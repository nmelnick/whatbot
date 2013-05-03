###########################################################################
# whatbot.pm
###########################################################################
#
# primary logic controller for whatbot
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot with whatbot::Role::Pluggable {
    use whatbot::Component::Base;
    use whatbot::Controller;
    use whatbot::Config;
    use whatbot::Log;

    use AnyEvent;
    use EV;
    use Class::Load qw(load_class);

    our $VERSION = '0.12';

    has 'base_component' => (
        is  => 'rw',
        isa => 'whatbot::Component::Base',
    );
    has 'initial_config' => (
        is  => 'rw',
        isa => 'whatbot::Config'
    );
    has 'kill_self' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );
    has 'version' => (
        is      => 'ro',
        isa     => 'Str',
        default => $VERSION,
    );
    has 'skip_extensions' => (
        is      => 'rw',
        isa     => 'Int',
        default => 0,
    );
    has 'last_message' => (
        is  => 'rw',
        isa => 'whatbot::Message',
    );
    has 'search_base' => (
        is      => 'ro',
        default => 'whatbot::Database::Table',
    );

    method config ( Str $basedir, Str $config_path? ) {
    
        # Find configuration file
        unless ( $config_path and -e $config_path ) {
        	my @try_config = (
        		'~/.whatbot/whatbot.conf',
        		'/usr/local/etc/whatbot/whatbot.conf',
        		'/usr/local/etc/whatbot.conf',
        		'/etc/whatbot/whatbot.conf',
        		'/etc/whatbot.conf',
        		$basedir . '/conf/whatbot.conf',
        	);
        	foreach (@try_config) {
        		if (-e $_) {
        			$config_path = $_;
        			last;
        		}
        	}
        	unless ( $config_path and -e $config_path ) {
        		print 'ERROR: Configuration file not found.' . "\n";
        		return;
        	}
        }
    	# Initialize configuration
    	my $config = whatbot::Config->new(
    		'config_file' => $config_path
    	);

        # Add core IO
        push( @{ $config->{'io'} }, { 'interface' => 'Timer' } );
        push( @{ $config->{'io'} }, { 'interface' => 'Async' } );

    	$self->initial_config($config);
    }

    method run ( $override_io? ) {
    	$self->report_error('Invalid configuration')
    	    unless ( defined $self->initial_config and $self->initial_config->config_hash );
	    
    	$self->initial_config->{'io'} = [$override_io] if ($override_io);
	
    	# Start Logger
    	my $log = whatbot::Log->new(
    		'log_directory' => $self->initial_config->log_directory
    	);
    	$self->report_error('Invalid configuration: Missing or unavailable log directory')
    	    unless ( defined $log and $log->log_directory );

    	# Build base component
    	my $base_component = whatbot::Component::Base->new(
    		'parent'	=> $self,
    		'config'	=> $self->initial_config,
    		'log'		=> $log
    	);
    	$self->base_component($base_component);
	
        # Initialize loadable modules
        $self->_initialize_models($base_component);
        my $ios = $self->_initialize_io($base_component);
	
    	# Parse Commands
    	my $controller = whatbot::Controller->new(
    		'base_component' 	=> $base_component,
    		'skip_extensions'	=> $self->skip_extensions
    	);
    	$base_component->controller($controller);
    	$controller->dump_command_map();
	
    	# Connect to IO
    	foreach my $io_object ( @$ios ) {
    		$log->write('Sending connect to ' . ref($io_object));
    		$io_object->controller($controller);
    		$io_object->connect();
    	}
	
    	# Start Event Loop
    	$log->write('whatbot initialized successfully.');
    	while ( not $self->kill_self ) {
    		foreach my $io_object ( @$ios ) {
    			$io_object->event_loop();
    		}
    	}
	
    	# Upon kill or interrupt, exit gracefully.
    	$log->write('whatbot exiting.');
    	foreach my $io_object ( @$ios ) {
    		$log->write('Sending disconnect to ' . ref($io_object));
    		$io_object->disconnect;
    	}
    }

    method report_error ( Str $error ) {
    	if ( defined $self->base_component and defined $self->base_component->log ) {
    		$self->base_component->log->error($error);
    	}
    	die 'ERROR: ' . $error;
    }

    method _initialize_models ( $base_component ) {
        # Find and store models
        $self->report_error( 
            'Invalid connection type: ' . $base_component->config->database->{'handler'} 
        ) unless ( $base_component->config->database and $base_component->config->database->{'handler'} );
        
        # Start database handler
        my $connection_class = 'whatbot::Database::' . $base_component->config->database->{'handler'};
        eval "require $connection_class";
        if ( my $err = $@ ) {
            $self->report_error( 'Problem loading $connection_class: ' . $err);
        }

        my $database = $connection_class->new(
            'base_component' => $base_component
        );
        $database->connect();
        $self->report_error('Configured connection failed to load properly')
            unless ( defined $database and defined $database->handle );
        $base_component->database($database);

        # Read in table definitions
        my %model;

        foreach my $class_name ( $self->plugins ) {
            next if ( $class_name =~ '::Row' );
            my @class_split = split( /\:\:/, $class_name );
            my $name = pop(@class_split);
        
            eval {
                load_class($class_name);
                $model{ lc($name) } = $class_name->new({
                    'base_component' => $base_component,
                    'handle'         => $database->handle
                });
            };
            if ($@) {
                warn 'Error loading ' . $class_name . ': ' . $@;
            } else {
                $base_component->log->write('-> ' . $class_name . ' loaded.');
            }
        };
        $base_component->models(\%model);
        return;
    }

    method _initialize_io ($base_component) {
        my @io;
        my %ios;
        foreach my $io_module ( @{ $self->initial_config->io } ) {
            $base_component->log->error('No interface designated for one or more IO modules')
                unless ( $io_module->{'interface'} );
        
            my $io_class = 'whatbot::IO::' . $io_module->{'interface'};
            eval "require $io_class";
            $self->report_error('Error loading ' . $io_class . ': ' . $@ ) if ($@);
            my $io_object = $io_class->new(
                'my_config'         => $io_module,
                'base_component'    => $base_component
            );
            $self->report_error('IO interface "' . $io_module->{'interface'} . '" failed to load properly') 
                unless ($io_object);

            $ios{ $io_object->name } = $io_object;
            push( @io, $io_object );
        }
        $base_component->ios(\%ios);
        return \@io;
    }
}

1;

=pod

=head1 NAME

whatbot - an extensible, sane chat bot for pluggable chat applications

=head1 DESCRIPTION

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
