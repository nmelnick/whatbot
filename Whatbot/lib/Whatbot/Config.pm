###########################################################################
# Config.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

Whatbot::Config - Config handler for whatbot

=cut

class Whatbot::Config {
	use JSON::XS;

	has 'config_file'   => ( is => 'rw', isa => 'Str' );
	has 'config_hash'   => ( is => 'rw', isa => 'HashRef' );
	has 'io'            => ( is => 'ro', isa => 'Any' );
	has 'store'         => ( is => 'ro', isa => 'Any' );
	has 'database'      => ( is => 'ro', isa => 'Any' );
	has 'commands'      => ( is => 'ro', isa => 'Any' );
	has 'log_directory' => ( is => 'ro', isa => 'Any' );

	method BUILD (...) {
		my $config;

		# Build config from built in hash if provided, otherwise, read from 
		# defined config file
		if ( $self->config_hash ) {
			$config = $self->config_hash;
		} else {
			die 'ERROR: Error finding config file "' . $self->config_file . '"!' unless ( -e $self->config_file );
			eval {
				open( my $fh, '<:utf8', $self->config_file ) or die 'Cannot read file';
				my $text;
				while(<$fh>) {
					$text .= $_;
				}
				close($fh);
				if ( $text =~ /^<Whatbot/ ) {
					die 'Configuration in XML. Please run bin/convert_xml_config.pl.';
				}
				$config = decode_json($text);
			};
			if ($@) {
				die 'ERROR: Error in config file "' . $self->config_file . '"! Parser reported: ' . $@;
			}
			$self->config_hash($config);
		}

		# Verify we have IO modules, and convert a single module to an array if necessary
		if (
			!$config->{'io'}
			or (
				ref($config->{'io'}) eq 'HASH'
				and scalar(keys %{$config->{'io'}}) == 0
			)
		) {
			die 'ERROR: No IO modules defined';
		}
		$config->{'io'} = [ $config->{'io'} ] if (ref($config->{'io'}) eq 'HASH');
		$self->{'io'} = $config->{'io'};
	
		$self->{'database'} = ( $config->{'database'} or {} );
		$self->{'commands'} = ( $config->{'commands'} or {} );
		$self->{'log_directory'} = ( $config->{'log'}->{'directory'} or '.' );
		$self->{'log_directory'} =~ s/\/$//;
	}
}

1;

=pod

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
