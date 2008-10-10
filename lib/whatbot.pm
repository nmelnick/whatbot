###########################################################################
# whatbot.pm
###########################################################################
#
# primary logic controller for whatbot
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot;
use Moose;

use whatbot::Component;
use whatbot::Controller;
use whatbot::Config;
use whatbot::Log;

our $VERSION = '0.9.5';

has 'base_component'    => ( is => 'rw', isa => 'whatbot::Component' );
has 'initial_config'    => ( is => 'rw', isa => 'whatbot::Config' );
has 'kill_self'         => ( is => 'rw', isa => 'Int', default => 0 );
has 'version'           => ( is => 'ro', isa => 'Str', default => $VERSION );
has 'skip_extensions'   => ( is => 'rw', isa => 'Int', default => 0 );

sub config {
    my ( $self, $basedir, $config_path ) = @_;
    
    # Find configuration file
    unless ($config_path and -e $config_path) {
    	my @try_config = (
    		$basedir . '/conf/whatbot.conf',
    		'/etc/whatbot/whatbot.conf',
    		'/etc/whatbot.conf',
    		'/usr/local/etc/whatbot/whatbot.conf',
    		'/usr/local/etc/whatbot.conf'
    	);
    	foreach (@try_config) {
    		$config_path = $_ if (-e $_);
    	}
    	unless ($config_path and -e $config_path) {
    		print 'ERROR: Configuration file not found.' . "\n";
    		return;
    	}
    }
	# Initialize configuration
	my $config = new whatbot::Config(
		'config_file' => $config_path
	);
	$self->initial_config($config);
}

sub run {
	my ( $self, $override_io ) = @_;
	
	$self->report_error('Invalid configuration')
	    unless ( defined $self->initial_config and $self->initial_config->config_hash );
	    
	$self->initial_config->{'io'} = [$override_io] if (defined $override_io);
	
	# Start Logger
	my $log = new whatbot::Log(
		'log_directory' => $self->initial_config->log_directory
	);
	$self->report_error('Invalid configuration')
	    unless ( defined $log and $log->log_directory );
	
	# Build base component
	my $base_component = new whatbot::Component(
		'parent'	=> $self,
		'config'	=> $self->initial_config,
		'log'		=> $log
	);
	$self->base_component($base_component);
	
	# Start Store module
	$self->report_error('Invalid store type')
	    unless ( $self->initial_config->store and $self->initial_config->store->{'handler'} );
	    
	my $storage = 'whatbot::Store::' . $self->initial_config->store->{'handler'};
	eval "require $storage";
	$self->report_error($@) if ($@);
	
	my $store = $storage->new(
		'base_component' => $base_component
	);
	$store->connect();
	$self->report_error('Configured store failed to load properly')
	    unless ( defined $store and defined $store->handle );
	$self->base_component->store($store);
	
	# Parse Commands
	my $controller = new whatbot::Controller(
		'base_component' 	=> $base_component,
		'skip_extensions'	=> $self->skip_extensions
	);
	$self->base_component->controller($controller);
	$store->controller($controller);
	$controller->dump_command_map();
	
	# Create IO modules
	my @io;
	foreach my $io_module ( @{$self->initial_config->io} ) {
		$log->write('ERROR: No interface designated for one or more IO modules')
		    unless ( defined $io_module->{'interface'} );
		
		my $io_class = 'whatbot::IO::' . $io_module->{'interface'};
		eval "require $io_class";
		$self->report_error($@) if ($@);
		my $io_object = $io_class->new(
			'my_config'		    => $io_module,
			'base_component' 	=> $base_component
		);
		$self->report_error('IO interface "' . $io_module->{'interface'} . '" failed to load properly') 
	        unless ( defined $io_object );

		push(@io, $io_object);
	}
	
	# Connect to IO
	foreach my $io_object (@io) {
		$log->write('Sending connect to ' . ref($io_object));
		$io_object->connect;
	}
	
	# Start Event Loop
	$log->write('whatbot initialized successfully.');
	while ( !$self->kill_self ) {
		foreach my $io_object (@io) {
			$io_object->event_loop();
		}
	}
	
	# Upon kill or interrupt, exit gracefully.
	$log->write('whatbot exiting.');
	foreach my $io_object (@io) {
		$log->write('Sending disconnect to ' . ref($io_object));
		$io_object->disconnect;
	}
}

sub report_error {
	my ( $self, $error ) = @_;
	
	if ( defined $self->base_component and defined $self->base_component->log ) {
		$self->base_component->log->write('ERROR: ' . $error);
	}
	die 'ERROR: ' . $error;
}

1;