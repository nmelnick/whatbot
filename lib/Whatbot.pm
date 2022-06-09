###########################################################################
# Whatbot.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

BEGIN {
  $Whatbot::VERSION = '0.2';
}

=head1 NAME

Whatbot - an extensible, sane chat bot for pluggable chat applications

=head1 DESCRIPTION

This bot was written purely as an exercise in futility, to try, desperately, to
replace the functionality of infobot without driving us insane. Part of that
goal has been accomplished, and so we leave it out there for the world to use.

Installing the 'Whatbot' module from CPAN will provide you with a decent set of
features, but you may actually want L<Task::whatbot> to provide all of the
plugins available from whatbot.org.

This is the primary entry point for the whatbot application, and is called
through the whatbot shell script.

=head1 INSTALLATION

Once Whatbot is installed, a configuration file must be added to configure the
services to connect to, as well as plugin-specific settings. The distribution
provides whatbot.conf-example to copy and alter to support an IRC connection
and a SQLite database. Additional configuration may be required for other
optional plugins. You may place whatbot.conf in /etc/whatbot, or provide the
path to the config file using the -c flag when executing whatbot.

To start, execute the 'whatbot' binary.

=cut

class Whatbot with Whatbot::Role::Pluggable {
  define VERSION = '0.2';
  use Whatbot::Controller;
  use Whatbot::Config;
  use Whatbot::Log;
  use Whatbot::State;
  use Whatbot::Message;

  use EV;
  use AnyEvent;
  use Class::Load qw(load_class);

  has 'initial_config' => (
    is  => 'rw',
    isa => 'Whatbot::Config'
  );
  has 'version' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {
      return VERSION;
    }
  );
  has 'skip_extensions' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
  );
  has 'last_message' => (
    is  => 'rw',
    isa => 'Whatbot::Message',
  );
  has 'search_base' => (
    is      => 'ro',
    default => 'Whatbot::Database::Table',
  );
  has 'loop' => (
    is => 'rw',
  );

  method config( Str $basedir, Str $config_path? ) {
  
    # Find configuration file
    unless ( $config_path and -e $config_path ) {
      my @try_config = (
        $ENV{'HOME'} . '/.whatbot/whatbot.conf',
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
    my $config = Whatbot::Config->new(
      'config_file' => $config_path
    );

    # Add core IO
    push( @{ $config->{'io'} }, { 'interface' => 'Timer' } );

    $self->initial_config($config);
  }

  method run( $override_io? ) {
    $self->report_error('Invalid configuration')
      unless ( defined $self->initial_config and $self->initial_config->config_hash );
    
    $self->initial_config->{'io'} = [$override_io] if ($override_io);
  
    # Start Logger
    my $log = Whatbot::Log->new(
      'log_directory' => $self->initial_config->log_directory
    );
    $self->report_error('Invalid configuration: Missing or unavailable log directory')
      unless ( defined $log and $log->log_directory );

    # Build state
    Whatbot::State->initialize({
      'parent' => $self,
      'config' => $self->initial_config,
      'log'    => $log
    });
  
    # Initialize loadable modules
    $self->_initialize_models();
    my $ios = $self->_initialize_io();
  
    # Parse Commands
    my $controller = Whatbot::Controller->new(
      'skip_extensions' => $self->skip_extensions
    );
    Whatbot::State->instance->controller($controller);
    $controller->dump_command_map();
  
    # Connect to IO
    foreach my $io_object ( @$ios ) {
      $log->write('Sending connect to ' . ref($io_object));
      $io_object->controller($controller);
      $io_object->connect();
    }
  
    # Start Event Loop
    $log->write('whatbot initialized successfully.');
    AnyEvent->signal(
      'signal' => 'INT',
      'cb'     => sub { $self->stop(); }
    );
    $SIG{'INT'} = sub { $self->stop(); };
    $self->loop( EV::run() );
  
    # Upon kill or interrupt, exit gracefully.
    $log->write('whatbot exiting.');
    foreach my $io_object ( @$ios ) {
      $log->write('Sending disconnect to ' . ref($io_object));
      $io_object->disconnect;
    }
    exit(0);
  }

  method report_error( Str $error ) {
    if ( Whatbot::State->instance and my $log = Whatbot::State->instance->log ) {
      $log->error($error);
    }
    die 'ERROR: ' . $error;
  }

  method _initialize_models() {
    my $state = Whatbot::State->instance;

    # Find and store models
    $self->report_error( 
      'Invalid connection type: ' . $state->config->database->{'handler'} 
    ) unless ( $state->config->database and $state->config->database->{'handler'} );
    
    # Start database handler
    my $connection_class = 'Whatbot::Database::' . $state->config->database->{'handler'};
    eval "require $connection_class";
    if ( my $err = $@ ) {
      $self->report_error( 'Problem loading $connection_class: ' . $err);
    }

    my $database = $connection_class->new();
    $database->connect();
    $self->report_error('Configured connection failed to load properly')
      unless ( defined $database and defined $database->handle );
    $state->database($database);

    # Read in table definitions
    my %model;

    foreach my $class_name ( $self->plugins ) {
      next if ( $class_name =~ '::Row' );
      my @class_split = split( /\:\:/, $class_name );
      my $name = pop(@class_split);
    
      eval {
        load_class($class_name);
        $model{ lc($name) } = $class_name->new({
          'handle' => $database->handle
        });
      };
      if ($@) {
        warn 'Error loading ' . $class_name . ': ' . $@;
      } else {
        $state->log->write('-> ' . $class_name . ' loaded.');
      }
    };
    $state->models(\%model);
    return;
  }

  method _initialize_io() {
    my @io;
    my %ios;
    my $state = Whatbot::State->instance;
    foreach my $io_module ( @{ $self->initial_config->io } ) {
      $state->log->error('No interface designated for one or more IO modules')
        unless ( $io_module->{'interface'} );
    
      my $io_class = 'Whatbot::IO::' . $io_module->{'interface'};
      eval "require $io_class";
      $self->report_error('Error loading ' . $io_class . ': ' . $@ ) if ($@);
      my $io_object = $io_class->new(
        'my_config'         => $io_module,
      );
      $self->report_error('IO interface "' . $io_module->{'interface'} . '" failed to load properly') 
        unless ($io_object);

      $ios{ $io_object->name } = $io_object;
      push( @io, $io_object );
    }
    $state->ios(\%ios);
    return \@io;
  }

  method stop() {
    Whatbot::State->instance()->log->write('Received interrupt.');
    EV::break();
  }
}

1;

=pod

=head1 LINKS

=over 4

=item Home page: L<http://www.whatbot.org/>

=item GitHub: L<http://github.com/nmelnick/whatbot>

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
