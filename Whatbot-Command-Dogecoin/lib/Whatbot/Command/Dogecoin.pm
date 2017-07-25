###########################################################################
# Whatbot/Command/Dogecoin.pm
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Dogecoin;
use Moose;
BEGIN { extends 'Whatbot::Command' }

use LWP::UserAgent ();
use Whatbot::Command::Cryptocurrency;
use Try::Tiny;
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

	my $bc = Whatbot::Command::Cryptocurrency->new({ name => 'Cryptocurrency' });
	$bc->register();
	my $pricing;
	try {
		$pricing = $bc->get_spot_price( 'BTC', uc($currency) );
	} catch {
		warn 'nah: ' . $_;
	}
	return 'Unable to reach server, sorry.' unless ($pricing);
	return $pricing * $btc_amount;
}

sub help {
    return 'Dogecoin checks the value of Dogecoin to the given currency, or USD.';
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Whatbot::Command::Dogecoin - Checks value of Dogecoin using Dogepay, and then
converts to USD through the L<Whatbot::Command::Bitcoin> command.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
