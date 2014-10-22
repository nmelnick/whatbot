###########################################################################
# Whatbot/Command/Bitcoin.pm
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Bitcoin;
use Moose;
BEGIN { extends 'Whatbot::Command' }

use JSON ();
use LWP::UserAgent ();
use HTML::Entities qw(decode_entities);
use HTML::Strip;
use HTTP::Headers;
use namespace::autoclean;

our $VERSION = '0.1';

has 'ua' => (
	is		=> 'ro',
	isa		=> 'LWP::UserAgent',
	default => sub {
		LWP::UserAgent->new(
			agent           => 'Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36',
			default_headers => HTTP::Headers->new(
				'X-Ver'           => 'river',
				'Referer'         => 'http://preev.com/btc/usd',
				'Host'            => 'preev.com',
				'Accept'          => '*/*',
				'Accept-Language' => 'en-US,en;q=0.8',
			),
		);
	}
);

has 'htmlstrip' => (
	is 		=> 'ro',
	isa 	=> 'HTML::Strip',
	default	=> sub { HTML::Strip->new; }
);

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub parse_message : GlobalRegEx('^(?i)bitcoin( \w+)?') {
	my ( $self, $message, $captures ) = @_;

	my $currency = lc( $captures->[0] or 'USD' );
	$currency =~ s/ //g;
	my $pricing = $self->_get_prices($currency);
	return 'Unable to reach server, sorry.' unless ($pricing);
	return $pricing unless ( ref($pricing) );
	return '1 BTC is worth ' . $self->_average_pricing($pricing) . ' ' . uc($currency) . '.';
}

sub _get_prices {
	my ( $self, $currency ) = @_;

	my $url = 'http://preev.com/pulse/units:btc+%s/sources:bitfinex+bitstamp+btce+localbitcoins';
	my $response = $self->ua->get( sprintf( $url, $currency ) );
	if ( $response->is_success ) {
		return 'Invalid currency, maybe?' unless ( $response->decoded_content() );
		my $pricing = JSON::from_json( $response->decoded_content() );
		return $pricing if ($pricing);
	}
	return;
}

sub _average_pricing {
	my ( $self, $pricing_object ) = @_;

	my $currencies = $pricing_object->{'btc'};
	my $first_currency = ( ( keys %$currencies )[0] );
	my $markets = $currencies->{$first_currency};
	my $total_volume = 0;
	my $weighted_numerator = 0;
	foreach my $market ( keys %$markets ) {
		my $price = sprintf( "%.10g", $markets->{$market}->{'last'} );
		my $vol = sprintf( "%.10g", $markets->{$market}->{'volume'} );
		$weighted_numerator += ( $price * $vol );
		$total_volume += $vol;
	}
	return sprintf( '%0.02f', $weighted_numerator / $total_volume );
}

sub help {
    return 'Bitcoin checks the value of bitcoin to the given currency, or USD.';
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Whatbot::Command::Bitcoin - Checks value of Bitcoin using Preev.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
