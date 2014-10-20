###########################################################################
# Whatbot/Command/Lightwire.pm
###########################################################################
# incredibly overcomplicated fake stock trading
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Lightwire;
use Moose;
BEGIN { extends 'Whatbot::Command' }
use namespace::autoclean;

use JSON;
use LWP::UserAgent ();
use HTML::Entities qw( decode_entities );
use HTML::Strip;
use URI::Escape qw( uri_escape );
use Data::Dumper qw( Dumper );

our $VERSION = '0.1';

my $ACCOUNT_ID = 3;
my $API_KEY    = "w4tb0t123412341234zzX";
my $BASE_URL   = "http://lightwire.herokuapp.com";

my $NOT_SET_UP_MSG = "you aren't set up for trading yet. Start with 'trade start with <currency>' where currency is whatever you want your base account to be denominated in.";

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

sub help : Command {
	return [
		'Lightwire is a completely made up stock market simulator that is way too complicated than is necessary.',
		'Actions: buy 4 msft, sell 4 msft',
		'  buyfx 100 USD with CAD, sellfx 100 USD for CAD',
		'  ex[ecute] <txn #>, ca[ncel] <txn #>',
		'Info: st[atus] (overall), forex|fx (details), sec[urities] (details), his[tory] (txns)',
		'Other: start with <currency> (sets you up with 5000 USD equiv in your chosen currency.)'
	];
}

sub buy : GlobalRegEx('^trade buy (\d+) (\S+)$') {
	return buy_sell('buy', @_);
}

sub sell : GlobalRegEx('^trade sell (\d+) (\S+)$') {
	return buy_sell('sell', @_);
}

sub buy_sell {
	my ( $type, $self, $message, $captures ) = @_;

	return "regex problem" unless ( $captures and @$captures );
	my ( $amount, $symbol ) = @$captures;

	my $user = lc($message->from);
	my $portfolio_id = $self->portfolio_id_for_user($user);

	if ($portfolio_id == 0) {
		return "$user: " . $NOT_SET_UP_MSG;
	}

	my $result = $self->lw_portfolio('post', $portfolio_id, 'stocktrade', symbol => $symbol, amount => $amount, tradetype => $type);
	return format_transaction($result);
}

sub buyforex : GlobalRegEx('^trade buyfx (\d+) (\S+) with (\S+)$') {
	return forex_buy_sell('buy', @_);
}

sub sellforex : GlobalRegEx('^trade sellfx (\d+) (\S+) for (\S+)$') {
	return forex_buy_sell('sell', @_);
}

sub forex_buy_sell {
	my ( $type, $self, $message, $captures ) = @_;

	return "regex problem" unless ( $captures and @$captures );
	my ( $amount, $target, $source ) = @$captures;

	my $user = lc($message->from);
	my $portfolio_id = $self->portfolio_id_for_user($user);

	if ($portfolio_id == 0) {
		return "$user: " . $NOT_SET_UP_MSG;
	}

	my $result = $self->lw_portfolio('post', $portfolio_id, 'currencytrade', source => $source, target => $target, amount => $amount, tradetype => $type);
	return format_transaction($result);
}

sub execute : GlobalRegEx('^trade ex(?:ecute)? (\d+)$') {
	return execute_cancel('execute', @_);
}

sub cancel : GlobalRegEx('^trade ca(?:ncel)? (\d+)$') {
	return execute_cancel('cancel', @_);
}

sub execute_cancel {
	my ( $cmd, $self, $message, $captures ) = @_;

	return "regex problem" unless ( $captures and @$captures );
	my ( $txn_id ) = @$captures;

	my $user = lc($message->from);
	my $portfolio_id = $self->portfolio_id_for_user($user);

	if ($portfolio_id == 0) {
		return "$user: " . $NOT_SET_UP_MSG;
	}

	my $result = $self->lw_txn($txn_id, $cmd);
	return format_transaction($result);
}

sub status : GlobalRegEx('^trade st(?:at(?:us)?)?$') {
	my ($self, $message) = @_;

	my $user = lc($message->from);
	my $portfolio_id = $self->portfolio_id_for_user($user);

	if ($portfolio_id == 0) {
		return "$user: " . $NOT_SET_UP_MSG;
	}

	my $result = $self->lw_portfolio('get', $portfolio_id, '');

	return format_status($result);
}
sub forex : GlobalRegEx('^trade (?:forex|fx)$') {
	simple_command('forex', @_);
}
sub securities : GlobalRegEx('^trade sec(?:urities)?$') {
	simple_command('securities', @_);
}
sub history : GlobalRegEx('^trade his(?:t(?:ory)?)?$') {
	simple_command('history', @_);
}
sub simple_command {
	my ($cmd, $self, $message) = @_;

	my $user = lc($message->from);
	my $portfolio_id = $self->portfolio_id_for_user($user);

	if ($portfolio_id == 0) {
		return "$user: " . $NOT_SET_UP_MSG;
	}

	my $result = $self->lw_portfolio('get', $portfolio_id, $cmd);

	return format_simple($result);
}

sub start : GlobalRegEx('^trade start with (\w+)$') {
	my ( $self, $message, $captures ) = @_;

	return "regex problem" unless ( $captures and @$captures );
	my ( $currency ) = @$captures;

	my $user = lc($message->from);
	my $portfolio_id = $self->portfolio_id_for_user($user);

	if ($portfolio_id != 0) {
		return "$user: You already have a trading account.";
	}

	my $error = $self->create_portfolio_for_user($user, $currency);

	return $error if $error;

	return "You're all set up, $user.";
}

# ----------------------------- non commands follow ----------

sub portfolio_id_for_user {
	my ( $self, $user ) = @_;

	return $self->model('Lightwire')->portfolio_id_for($user);
}

sub create_portfolio_for_user {
	my ( $self, $user, $base_currency ) = @_;

	my $p = $self->lw_account('post', 'portfolios', name => $user, base_currency => $base_currency);

	if (!ref($p)) {
		return $p;
	}

	$self->model('Lightwire')->set_portfolio_id_for($user, $p->{'id'});

	return "";
}

sub lw_account {
	my ( $self, $method, $action, %params ) = @_;

	my $url = $BASE_URL . "/accounts/$ACCOUNT_ID/$action";
	$params{'key'} = $API_KEY;

	my $result = $self->lw_get_or_post($method, $url, %params);
	return parse_result($result);
}

sub lw_portfolio {
	my ( $self, $method, $portfolio_id, $action, %params ) = @_;

	my $url = $BASE_URL . "/accounts/$ACCOUNT_ID/portfolios/$portfolio_id/$action";
	$params{'key'} = $API_KEY;

	my $result = $self->lw_get_or_post($method, $url, %params);
	return parse_result($result);
}

sub lw_get_or_post {
	my ( $self, $method, $url, %params ) = @_;

	if ($method eq 'get'){
		if (%params) {
			my @mapped = map { $_ . "=" . uri_escape($params{$_}) } keys(%params);
			$url = $url . "?" . join('&', @mapped);
		}
		return $self->ua->get($url, "Accept" => "application/json");
	} else {
		return $self->ua->post($url, "Accept" => "application/json", Content => \%params);
	}
}


sub lw_txn {
	my ( $self, $txn_id, $action ) = @_;

	my $url = $BASE_URL . "/transactions/$txn_id/$action";

	my $result = $self->lw_get_or_post('post', $url, key => $API_KEY);
	return parse_result($result);
}


my %ACTIONS = (
	5 => 'buy',
	6 => 'sell',
	7 => 'buy forex',
	8 => 'sell forex',
);

my %STATUSES = (
	4 => 'open',
	5 => 'closed',
	6 => 'cancelled'
);

sub format_transaction {
	my ( $txn ) = @_;

	if (!ref($txn)) {
		return $txn; # it's a string or something
	}

	my $action = $ACTIONS{$txn->{'action_id'}};
	my $status = $STATUSES{$txn->{'transaction_status_id'}};
	my $last_time = $txn->{'time_closed'} ? $txn->{'time_closed'} : $txn->{'time_opened'};

	my $cost = sprintf "%.2f", $txn->{'cost'};
	my $fee  = sprintf "%.2f", $txn->{'fee'};

	# hide implementation secrets!!
	my $target = $txn->{'target'};
	$target =~ s/\w{3}=X$//;

	return "txn $txn->{'id'} $status at $last_time: $action $txn->{'count'} $target for $cost $txn->{'currency'} (+ $fee fee)"
}

sub format_simple {
	my ( $structure ) = @_;

	if (ref($structure) eq "ARRAY") {
		if (scalar(@$structure) == 0) {
			return "nothing returned";
		}
		my @strings;
		my $total = 0;
		my $curr = '';

		foreach my $s (@$structure) {
			my %h = %$s;
			if (exists $h{'iso'}) {
				push @strings, "  $h{'iso'} $h{'amount'} (now: ". join(' ', @{$h{'market_value'}}) .")";
			} else {
				push @strings, "  $h{'amount'} $h{'symbol'} (now: ". join(' ', @{$h{'market_value'}}) .")";
			}
			$total += $h{'market_value'}[1];
			$curr = $h{'market_value'}[0];
		}
		push @strings, "total: $curr $total\n";
		return join(', ', @strings);
	} elsif (ref($structure)) {
		return Dumper($structure);
	} else {
		return $structure;
	}
}

sub format_status {
	my ( $st ) = @_;

	if (ref($st)) {

		my @strings;

		my (@stocks, @currencies);
		@stocks = map { $_->{'amount'} . " ". $_->{'symbol'} } @{$st->{'stock_assets'}} if exists $st->{'stock_assets'};
		@currencies = map { $_->{'amount'} . " ". $_->{'iso'} } @{$st->{'currency_assets'}} if exists $st->{'currency_assets'};

		my $assets = "";
		$assets .= join(', ', @stocks) if @stocks;
		$assets .= " // " if (@stocks && @currencies);
		$assets .= join(', ', @currencies) if @currencies;
		push @strings, $assets;

		my @nmv    = @{$st->{'net_market_value'}};
		my @margin = @{$st->{'total_margin'}};

		$nmv[1] = sprintf "%.2f", $nmv[1];
		$margin[1] = sprintf "%.2f", $margin[1];

		my $nmv_s = join(' ', @nmv);
		my $mar_s = join(' ', @margin);

		push @strings, "net market value for $st->{'name'}: $nmv_s // margin used: $mar_s";

		return \@strings;
	} else { # error or something?
		return $st;
	}
}

sub parse_result {
	my ( $result ) = @_;

	if ($result->is_success) {
		return decode_json $result->decoded_content;
	} elsif ($result->code == 500) {
		return "haha, 500 server error, mike sucks";
	} elsif ($result->code == 404) {
		return "404'd!"
	} else {
		return $result->decoded_content;
	}
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Whatbot::Command::Lightwire - incredibly overcomplicated fake stock trading

=head1 DESCRIPTION

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
