###########################################################################
# whatbot/Command/Weather.pm
###########################################################################
# Get a simple weather report
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Weather;
use Moose;
BEGIN { extends 'whatbot::Command'; }
use namespace::autoclean;
use LWP::UserAgent;
use JSON::XS;
use Convert::Temperature;

our $VERSION = '0.1';

has 'api_key' => (
	'is'  => 'rw',
	'isa' => 'Str',
);

has 'ua' => (
	is		=> 'ro',
	isa		=> 'LWP::UserAgent',
	default => sub { LWP::UserAgent->new( 'timeout' => 15 ); }
);

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);

	if ( $self->my_config and $self->my_config->{'api_key'} ) {
		$self->api_key( $self->my_config->{'api_key'} );
	}
	
	return;
}

sub temp_string {
	my ( $self, $temp ) = @_;
	my $conv = new Convert::Temperature();

	return sprintf(
		'%d F (%0.2f C)',
		$temp,
		$conv->from_fahr_to_cel($temp)
	);

}

sub location {
	my ( $self, $location ) = @_;
	my $query;

	if ( $location =~ /^\d{5}$/ ) {
		$query = $location;
	} elsif ( $location =~ /([^,]+), (\w\w+)/ ) {
		$query = $2 . '/' . $1;
	} elsif ( $location =~ /([^,]+), (\w{2})/ ) {
		$query = $2 . '/' . $1;
	}

	return $query;
}

sub fetch_and_decode {
	my ( $self, $url ) = @_;

	my $response = $self->ua->get($url);
	my $content = $response->decoded_content;

	# Nothing is compliant, so if headers appear in the response, separate them.
	if ( $content =~ /Content\-Type/ ) {
		my ( $headers, @contents ) = split( /\n\n/, $content );
		$content = join( '', @contents );
		$content =~ s/\s*0\s*$//;
	}

	# What the eff, wunderground
	$content =~ s/\s+ef1\s+//g;

	return decode_json( $content );
}

sub forecast : GlobalRegEx('^forecast (.*)') {
	my ( $self, $message, $captures ) = @_;

	return unless ( $self->api_key );

	my $query = $self->location($captures->[0]);
	
	unless (defined $query) {
		return "Unwilling to figure out what you meant by: " . $captures->[0];
	}

	my $url = sprintf(
		'http://api.wunderground.com/api/%s/forecast/q/%s.json',
		$self->api_key,
		$query
	);
	my $json = $self->fetch_and_decode($url);

	my $forecasts = $json->{'forecast'}->{'txt_forecast'}->{'forecastday'};

	my $buffer = [];
	foreach my $forecast ( @{ $forecasts } ) {
		push( @$buffer, sprintf("%s: %s", $forecast->{'title'}, $forecast->{'fcttext'}) );
	}

	return $buffer;
}

sub weather : GlobalRegEx('^weather (.*)') {
	my ( $self, $message, $captures ) = @_;

	return unless ( $self->api_key );

	my $query = $self->location($captures->[0]);

	unless(defined $query) {
		return 'Unwilling to figure out what you meant by: ' . $captures->[0];	
	}

	my $url = sprintf(
		'http://api.wunderground.com/api/%s/conditions/alerts/q/%s.json',
		$self->api_key,
		$query
	);
	my $json = $self->fetch_and_decode($url);

	if ( my $current = $json->{'current_observation'} ) {
		return sprintf(
			'Weather for %s: Currently %s and %s, feels like %s. %s',
			$current->{'display_location'}->{'full'},
			$current->{'weather'},
			$self->temp_string($current->{'temp_f'}),
			$self->temp_string($current->{'feelslike_f'}),
			( $json->{'alerts'} and @{ $json->{'alerts'} } ?
				'Alert: ' . $json->{'alerts'}->[0]->{'description'}
				: ''
			)
		);
	}
	return 'Iunno.';
}

sub help {
	my ( $self ) = @_;
	
	return [
		'Weather grabs the temperature and alerts for a zip code or "City, Country".',
		'Usage: weather 10101',
		'Usage: weather Toronto, Canada',
		'Usage: forecast 10101'
	];
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

whatbot::Command::Weather - Get weather information for US and world

=head1 SYNOPSIS

Config:

"weather" : {
	"api_key" : "12345678abcdef90"
}

=head1 DESCRIPTION

whatbot::Command::Weather will use the Wunderground API to retrieve weather
information. To do this, you will need to sign up for a free API key from the
wunderground API site.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
