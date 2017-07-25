###########################################################################
# Whatbot/Command/Cryptocurrency.pm
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;
use Whatbot::Command;

class Whatbot::Command::Cryptocurrency extends Whatbot::Command with Whatbot::Role::UserAgent {
	use JSON ();
	use HTML::Entities qw(decode_entities);
	use Try::Tiny;

	our $VERSION = '0.1';

	method register() {
		$self->command_priority('Extension');
		$self->require_direct(0);

		# Coinbase requires a CB-VERSION header, no need to set it every call.
		$self->ua->default_header( 'CB-VERSION' => '2017-05-19' );

		return;
	}

	method help(...) : Command {
		return [
			'Cryptocurrency checks the value of various cryptocurrency to the given currency, or USD. ' .
			'Use it by providing the name of the currency, and the currency to convert to, like "bitcoin usd". ' .
			'If a second currency is not provided, usd is used by default.',
			'Available cryptocurrency: bitcoin, litecoin, ethereum',
		];
	}

	method bitcoin( $message, $captures ) : GlobalRegEx('^(?i)bitcoin( \w+)?') {
		return $self->check_spot( 'BTC', $captures->[0] );
	}

	method litecoin( $message, $captures ) : GlobalRegEx('^(?i)litecoin( \w+)?') {
		return $self->check_spot( 'LTC', $captures->[0] );
	}

	method ethereum( $message, $captures ) : GlobalRegEx('^(?i)ethereum( \w+)?') {
		return $self->check_spot( 'ETH', $captures->[0] );
	}

	method check_spot( $from, $to ) {
		$to = uc( $to or 'USD' );
		$to =~ s/ //g;
		my $amount;
		my $error = try {
			$amount = $self->get_spot_price( $from, $to );
			return;
		} catch {
			if ( $_ =~ /Invalid/ ) {
				s/ at.*$//;
				s/[\r\n]//;
				return $_;
			}
		};
		return $error if ($error);
		if ($amount) {
			return sprintf( '1 %s is worth %s in %s.', $from, $amount, $to );
		}
		return 'Unable to reach server or invalid response from server, sorry.';
	}

	method get_spot_price( $from, $to ) {
		my $response = $self->ua->get( sprintf('https://api.coinbase.com/v2/prices/%s-%s/spot', $from, $to ) );
		if ( $response->is_success ) {
			my $pricing_object = JSON::from_json( $response->decoded_content );
			if ($pricing_object->{data}->{amount}) {
				return $pricing_object->{data}->{amount};
			} else {
				$self->log->error('Coinbase API Error: No data->amount');
				return;
			}
		} else {
			my $pricing_object = JSON::from_json( $response->decoded_content );
			if ( $pricing_object and $pricing_object->{errors} ) {
				my $message = $pricing_object->{errors}->[0]->{message};
				if ( $message =~ /^Invalid currency/ ) {
					die $message;
				}
				$self->log->error( 'Coinbase API Error: ' . $pricing_object->{errors}->[0]->{message} );
				return;
			}
			$self->log->error( 'Error contacting Coinbase: ' . $response->status_line . " - " . $response->decoded_content );
		}
		return;
	}

}

1;

=pod

=head1 NAME

Whatbot::Command::Cryptocurrency - Checks value of Cryptocurrency using Coinbase.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
