###########################################################################
# whatbot/Command/Dogecoin.pm
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Dogecoin;
use Moose;
BEGIN { extends 'whatbot::Command' }

use LWP::UserAgent ();
use whatbot::Command::Bitcoin;
use namespace::autoclean;

our $VERSION = '0.1';

has 'ua' => (
	is		=> 'ro',
	isa		=> 'LWP::UserAgent',
	default => sub { LWP::UserAgent->new; }
);

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub parse_message : GlobalRegEx('^(?i)dogecoin( \w+)?') {
	my ( $self, $message, $captures ) = @_;

	my $currency = lc( $captures->[0] or 'USD' );
	$currency =~ s/ //g;
	my $pricing = $self->_doge_to_btc();
	return 'Unable to reach server, sorry.' unless ($pricing);
	return $pricing unless ( ref($pricing) );
	my $currency_value = $self->_btc_to_currency( $pricing->{btc}, $currency );
	return $currency_value unless ( $currency_value and $currency_value =~ /^[\d\.]+$/ );
	return '1000 DOGE is worth ' . $currency_value . ' ' . uc($currency) . '.';
}

sub _doge_to_btc {
	my ( $self ) = @_;

	my $url = 'http://dogepay.com/frame_converter.php?v=1000&from_type=DOGE&to_type=BTC';
	my $response = $self->ua->get($url);
	if ( $response->is_success ) {
		return 'Invalid maybe?' unless ( $response->decoded_content() );
		if ( $response->decoded_content() =~ /= BTC ([\d\.]+)/ ) {
			return {
				'btc' => $1,
			};
		}
	}
	return;
}

sub _btc_to_currency {
	my ( $self, $btc_amount, $currency ) = @_;

	my $bc = whatbot::Command::Bitcoin->new({ name => 'Bitcoin' });
	my $pricing = $bc->_get_prices($currency);
	return 'Unable to reach server, sorry.' unless ($pricing);
	return $pricing unless ( ref($pricing) );
	my $price = $bc->_average_pricing($pricing);
	if ( $price and $price =~ /^[\d\.]+$/ ) {
		return sprintf( '%0.5f', $price * $btc_amount );
	}
}

sub help {
    return 'Dogecoin checks the value of Dogecoin to the given currency, or USD.';
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

whatbot::Command::Dogecoin - Checks value of Dogecoin.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
