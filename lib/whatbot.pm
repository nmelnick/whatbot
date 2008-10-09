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

our $VERSION = "0.9.5";

has 'baseComponent'     => ( is => 'rw', isa => 'whatbot::Component' );
has 'killSelf'          => ( is => 'rw', isa => 'Int', default => 0 );
has 'version'           => ( is => 'ro', isa => 'Str', default => $VERSION );
has 'skipExtensions'    => ( is => 'rw', isa => 'Int', default => 0 );

sub run {
	my ( $self, $configPath, $overrideIo ) = @_;
	
	# Initialize configuration
	my $config = new whatbot::Config(
		configFile	=> $configPath
	);
	$self->reportError('Invalid configuration')
	    unless (defined $config and $config->configHash);
	    
	$config->{io} = [$overrideIo] if (defined $overrideIo);
	
	# Start Logger
	my $log = new whatbot::Log(
		logDirectory	=> $config->logDirectory
	);
	$self->reportError('Invalid configuration')
	    unless (defined $log and $log->logDirectory);
	
	# Build base component
	my $baseComponent = new whatbot::Component(
		parent	=> $self,
		config	=> $config,
		log		=> $log
	);
	$self->baseComponent($baseComponent);
	
	# Start Store module
	$self->reportError('Invalid store type')
	    if (!defined $config->store or !defined $config->store->{handler});
	    
	my $storage = 'whatbot::Store::' . $config->store->{handler};
	eval "require $storage";
	if ($@) {
		$self->reportError($@);
	}
	my $store = $storage->new(
		baseComponent => $baseComponent
	);
	$store->connect;
	$self->reportError('Configured store failed to load properly') unless (defined $store and defined $store->handle);
	$self->baseComponent->store($store);
	
	# Parse Commands
	my $controller = new whatbot::Controller(
		baseComponent 	=> $baseComponent,
		skipExtensions	=> $self->skipExtensions
	);
	$self->baseComponent->controller($controller);
	$store->controller($controller);
	
	# Create IO modules
	my @io;
	foreach my $ioModule (@{$config->io}) {
		$log->write("ERROR: No interface designated for one or more IO modules") unless (defined $ioModule->{interface});
		
		my $ioClass = "whatbot::IO::" . $ioModule->{interface};
		eval "require $ioClass";
		if ($@) {
			$self->reportError($@);
		}
		my $ioObject = $ioClass->new(
			myConfig		=> $ioModule,
			baseComponent 	=> $baseComponent
		);
		$self->reportError('IO interface '" . $ioModule->{interface} . "' failed to load properly') unless (defined $ioObject);
		push(@io, $ioObject);
	}
	
	# Connect to IO
	foreach my $ioObject (@io) {
		$log->write("Sending connect to " . ref($ioObject));
		$ioObject->connect;
	}
	
	# Start Event Loop
	$log->write("whatbot initialized successfully.");
	while (!$self->killSelf) {
		foreach my $ioObject (@io) {
			$ioObject->eventLoop();
		}
	}
	
	# Ding
	$log->write("whatbot exiting.");
	foreach my $ioObject (@io) {
		$log->write("Sending disconnect to " . ref($ioObject));
		$ioObject->disconnect;
	}
}

sub reportError {
	my ($self, $error) = @_;
	if (defined $self->baseComponent and defined $self->baseComponent->log) {
		$self->baseComponent->log->write("ERROR: " . $error);
	}
	die "ERROR: " . $error;
}

1;