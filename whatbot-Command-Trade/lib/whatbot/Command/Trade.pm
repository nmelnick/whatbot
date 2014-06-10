###########################################################################
# Trade.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Trade;
use Moose;
BEGIN { extends 'whatbot::Command' }
use namespace::autoclean;
use whatbot::Command::Market;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub help {
	return [
		'Trade is a completely made up stock market simulator, and not a very '
		. 'good one. Use trade to "buy" and "sell" stock based on current '
		. 'market value as provided by the Market command. You are allowed to '
		. 'retain a negative balance, and you get nothing for your troubles.',
		' * buy: Buy shares. (trade buy 5 shares of msft)',
		' * sell: Sell shares. (trade sell 4 shares of msft)',
		' * shares: Get holdings of ticker. (trade shares msft)',
		' * holdings: Show what you have. (trade holdings)',
		' * balance: See current account balance. (trade balance)'
	];
}

sub buy : Command {
	my ( $self, $message, $captures ) = @_;

	my ( $number_shares, $ticker, $price ) = $self->parse_hurf($captures);
	unless ( $number_shares and $ticker) {
		return 'Trade has no idea what that meant. Read help.';
	}
	unless ( $price ) {
		return sprintf( 'Ticker symbol %s was not found.', $ticker );
	}
	if ( $number_shares < 1 or $number_shares !~ /^\d+$/ ) {
		return 'Trade requires a valid, positive, whole number of shares.';
	}

	my $result = $self->model('Trade')->trade( lc( $message->from ), $number_shares, $ticker, $price );
	if ($result) {
		return sprintf( "%s, you purchased %d shares of %s at %0.2f, totalling %0.2f minus %0.2f fee. Your balance is %0.2f.", $message->from, $number_shares, $ticker, $price, ( $price * $number_shares ), $self->model('Trade')->trade_fee, $self->model('Trade')->balance( lc( $message->from ) ) );
	}
	return 'Uh.';
}

sub sell : Command {
	my ( $self, $message, $captures ) = @_;

	my ( $number_shares, $ticker, $price ) = $self->parse_hurf($captures);
	unless ( $number_shares and $ticker) {
		return 'Trade has no idea what that meant. Read help.';
	}
	unless ( $price ) {
		return sprintf( 'Ticker symbol %s was not found.', $ticker );
	}
	if ( $number_shares < 1 or $number_shares !~ /^\d+$/ ) {
		return 'Trade requires a valid, positive, whole number of shares.';
	}

	my $user = lc( $message->from );

	# Do we have that many shares
	my $shares = $self->model('Trade')->get_share_count( $user, $ticker );
	if ( $shares < $number_shares ) {
		return sprintf( "%s, you have %d shares of %s. You cannot sell %d shares.", $message->from, $shares, $ticker, $number_shares );
	}

	# Perform trade
	my $result = $self->model('Trade')->trade( $user, ( $number_shares * -1 ), $ticker, $price );
	if ($result) {
		return sprintf( "%s, you sold %d shares of %s at %0.2f, totalling %0.2f minus %0.2f fee. Your balance is %0.2f.", $message->from, $number_shares, $ticker, $price, ( $price * $number_shares ), $self->model('Trade')->trade_fee, $self->model('Trade')->balance( lc( $message->from ) ) );
	}
	return 'Uh.';
}

sub balance : Command {
	my ( $self, $message ) = @_;

	my $balance = $self->model('Trade')->balance( lc( $message->from ) );
	return sprintf( '%s, your balance is %0.2f.', $message->from, $balance );
}

sub holdings : Command {
	my ( $self, $message ) = @_;

	my $holdings = $self->model('Trade')->holdings( lc( $message->from ) );
	return join( ", ", ( map { sprintf( '%s: %d (%0.2f)', $_, $holdings->{$_}, ( $holdings->{$_} * $self->price_for_ticker($_) ) ) } keys %$holdings ) );
}

sub shares : Command {
	my ( $self, $message, $captures ) = @_;

	my $ticker = uc( $captures->[0] );
	my $shares = $self->model('Trade')->get_share_count( lc( $message->from ), $ticker );
	return sprintf( '%s, you have %d share%s of %s, valued at %0.2f.', $message->from, $shares, ( $shares != 1 ? 's' : '' ), $ticker, ( $shares * $self->price_for_ticker($ticker) ) );
}

sub parse_hurf {
	my ( $self, $captures ) = @_;

    my $search_text = join( ' ', @$captures );
    return unless ($search_text);

    # Parse message
    my $shares;
    my $ticker;
    if ( $search_text =~ /([\d\.]+) (shares? )?of (\w+)/ ) {
    	$shares = $1;
    	$ticker = $3;
    }
    return unless ( $shares and $ticker );

    # Validate ticker
    my $price = $self->price_for_ticker($ticker);

    return ( $shares, $ticker, $price );
}

sub price_for_ticker {
	my ( $self, $ticker ) = @_;

    my $market = whatbot::Command::Market->new(
		'base_component' => $self->base_component,
		'my_config'      => {},
		'name'           => 'Market'
	);
	my $string_result = $market->parse_message( undef, [$ticker] );
	$string_result =~ s/[^ \-0-9A-Za-z\(\)\.]//g;
	if ( $string_result =~ /couldnt find/ ) {
		return;
	} elsif ( $string_result =~ /\s([\d\.]+)\s*\d{2}\-?[\d\.]+\s*\(/ ) {
		return $1;
	}
	return;
}

__PACKAGE__->meta->make_immutable;

1;

