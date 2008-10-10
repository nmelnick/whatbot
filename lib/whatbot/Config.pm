###########################################################################
# whatbot/Config.pm
###########################################################################
#
# whatbot config handler
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Config;
use Moose;

use XML::Simple;

has 'config_file'   => ( is => 'rw', isa => 'Str' );
has 'config_hash'   => ( is => 'rw', isa => 'HashRef' );
has 'io'            => ( is => 'ro', isa => 'Any' );
has 'store'         => ( is => 'ro', isa => 'Any' );
has 'commands'      => ( is => 'ro', isa => 'Any' );
has 'log_directory' => ( is => 'ro', isa => 'Any' );

sub BUILD {
	my ($self) = @_;
	
	die 'ERROR: Error finding config file "' . $self->config_file . '"!' unless ( -e $self->config_file );
	my $config;
	eval {
		$config = XMLin($self->config_file);
	};
	if ($@) {
		die 'ERROR: Error in config file "' . $self->config_file . '"! Parser reported: ' . $@;
	} else {
		$self->config_hash($config);
		
		# Verify we have IO modules, and convert a single module to an array if necessary
		if (!$config->{'io'} or (ref($config->{'io'}) eq 'HASH' and scalar(keys %{$config->{'io'}}) == 0)) {
			die 'ERROR: No IO modules defined';
		}
		$config->{'io'} = [ $config->{'io'} ] if (ref($config->{'io'}) eq 'HASH');
		$self->{'io'} = $config->{'io'};
		
		$self->{'store'} = ($config->{'store'} or {});
		$self->{'commands'} = ($config->{'commands'} or {});
		$self->{'log_directory'} = ($config->{'log'}->{'directory'} or '.');
		$self->{'log_directory'} =~ s/\/$//;
	}
}

1;