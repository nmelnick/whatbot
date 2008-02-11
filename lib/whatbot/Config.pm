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

has 'configFile' => ( is => 'rw', isa => 'Str' );
has 'configHash' => ( is => 'rw', isa => 'HashRef' );
has 'io' => ( is => 'ro', isa => 'Any' );
has 'store' => ( is => 'ro', isa => 'Any' );
has 'commands' => ( is => 'ro', isa => 'Any' );
has 'logDirectory' => ( is => 'ro', isa => 'Any' );

sub BUILD {
	my ($self) = @_;
	
	die "ERROR: Error finding config file '" . $self->configFile . "'!" unless (-e $self->configFile);
	my $config;
	eval {
		$config = XMLin($self->configFile);
	};
	if ($@) {
		die "ERROR: Error in config file '" . $self->configFile . "'! Parser reported: \n" . $@;
	} else {
		$self->configHash($config);
		
		# Verify we have IO modules, and convert a single module to an array if necessary
		if (!$config->{io} or (ref($config->{io}) eq 'HASH' and scalar(keys %{$config->{io}}) == 0)) {
			die "ERROR: No IO modules defined";
		}
		$config->{io} = [ $config->{io} ] if (ref($config->{io}) eq 'HASH');
		$self->{io} = $config->{io};
		
		$self->{store} = ($config->{store} or {});
		$self->{commands} = ($config->{commands} or {});
		$self->{logDirectory} = ($config->{log}->{directory} or ".");
		$self->{logDirectory} =~ s/\/$//;
	}
}

1;