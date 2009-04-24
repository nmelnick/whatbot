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

use Data::Dumper;
use whatbot::Component;
use whatbot::Controller;
use whatbot::Config;
use whatbot::Log;
use whatbot::Timer;

our $VERSION = '0.9.5';

has 'base_component'    => ( is => 'rw', isa => 'whatbot::Component' );
has 'initial_config'    => ( is => 'rw', isa => 'whatbot::Config' );
has 'kill_self'         => ( is => 'rw', isa => 'Int', default => 0 );
has 'version'           => ( is => 'ro', isa => 'Str', default => $VERSION );
has 'skip_extensions'   => ( is => 'rw', isa => 'Int', default => 0 );
has 'last_message'      => ( is => 'rw', isa => 'whatbot::Message' );

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
	    
	$self->initial_config->{'io'} = [$override_io] if ($override_io);
	
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
	
	# Find and store models
	$self->report_error( 'Invalid connection type: ' . $self->initial_config->connection->{'handler'} )
	    unless ( $self->initial_config->connection and $self->initial_config->connection->{'handler'} );
	    
	my $connection_class = 'whatbot::Connection::' . $self->initial_config->connection->{'handler'};
	eval "require $connection_class";
	$self->report_error($@) if ($@);
	
	my $connection = $connection_class->new(
	    'base_component' => $base_component
	);
	$connection->connect();
	$self->report_error('Configured connection failed to load properly')
	    unless ( defined $connection and defined $connection->handle );
	$base_component->connection($connection);
	
	my %model;
	my $root_dir = $INC{'whatbot/Controller.pm'};
	$root_dir =~ s/Controller\.pm$/Connection\/Table/;
	opendir( MODEL_DIR, $root_dir );
	while ( my $name = readdir(MODEL_DIR) ) {
		next unless ( $name =~ /^[A-z0-9]+\.pm$/ and $name ne 'Row.pm' );
		
		my $command_path = $root_dir . '/' . $name;
		$name =~ s/\.pm//;
		my $class_name = 'whatbot::Connection::Table::' . $name;
		eval {
		    eval "require $class_name";
    		$model{ lc($name) } = $class_name->new(
    		    'base_component' => $base_component,
    		    'handle'         => $connection->handle
    		);
    	};
    	if ($@) {
    	    warn 'Error loading ' . $class_name . ': ' . $@;
    	} else {
			$log->write('-> ' . $class_name . ' loaded.');
    	}
	};
	$base_component->models(\%model);
	
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
	
	# 10 RANDOMIZE TIMER
	my $timer = new whatbot::Timer(
		'base_component' 	=> $base_component
	);
	$self->base_component->timer($timer);
	
	# Create IO modules
	my @io;
	my %ios;
	foreach my $io_module ( @{$self->initial_config->io} ) {
		$log->error('No interface designated for one or more IO modules')
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

		$ios{ $io_object->name } = $io_object;
		push(@io, $io_object);
	}
	$base_component->ios(\%ios);
	
	# Parse Commands
	my $controller = new whatbot::Controller(
		'base_component' 	=> $base_component,
		'skip_extensions'	=> $self->skip_extensions
	);
	$self->base_component->controller($controller);
	$store->controller($controller);
	$controller->dump_command_map();
	
	# Connect to IO
	foreach my $io_object (@io) {
		$log->write('Sending connect to ' . ref($io_object));
		$io_object->controller($controller);
		$io_object->connect;
	}
	
	# Start Event Loop
	$log->write('whatbot initialized successfully.');
	while ( !$self->kill_self ) {
		foreach my $io_object (@io) {
			$io_object->event_loop();
		}
		$timer->tick();
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
		$self->base_component->log->error($error);
	}
	die 'ERROR: ' . $error;
}

1;