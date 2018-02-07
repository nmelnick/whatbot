###########################################################################
# Whatbot/Command/Market.pm
###########################################################################
# grabs currency rates and stocks, for lols
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Market;
use Moose;
BEGIN { extends 'Whatbot::Command' }
use namespace::autoclean;

use HTML::TreeBuilder::XPath;
use String::IRC; # for colors!
use Date::Parse;

our $VERSION = '0.1';

my $URL_BASE = 'http://finance.google.com/finance?q=';

# Example data
# $VAR1 = {
#           'dataSource' => 'NASDAQ real-time data',
#           'afterHoursPriceChangePercent' => '0.62',
#           'url' => 'https://www.google.com/finance?cid=694653',
#           'open' => "\x{a0}\x{a0}\x{a0}\x{a0}-",
#           'exchange' => 'NASDAQ',
#           'afterHoursQuoteTime' => '2016-10-27T12:38:08Z',
#           'market_cap' => '551.16B',
#           'priceChange' => '0.00',
#           'afterHoursPriceChange' => '+4.93',
#           'priceChangePercent' => '0.00',
#           'shares' => '343.60M',
#           'vol_and_avg' => '8,968.00/1.36M',
#           'exchangeTimezone' => 'America/New_York',
#           'range' => "\x{a0}\x{a0}\x{a0}\x{a0}-",
#           'pe_ratio' => '30.38',
#           'afterHoursPrice' => '804.00',
#           'eps' => '26.30',
#           'dataSourceDisclaimerUrl' => '//www.google.com/help/stock_disclaimer.html#realtime',
#           'isPreMarket' => 'true',
#           'name' => 'Alphabet Inc',
#           'priceCurrency' => 'USD',
#           'inst_own' => '70%',
#           'price' => '799.07',
#           'latest_dividend-dividend_yield' => "\x{a0}\x{a0}\x{a0}\x{a0}-",
#           'imageUrl' => 'https://www.google.com/finance/chart?cht=g&q=NASDAQ:GOOG&tkr=1&p=1d&enddatetime=2016-10-26T16:00:01Z',
#           'beta' => "\x{a0}\x{a0}\x{a0}\x{a0}-",
#           'range_52week' => '663.06 - 816.68',
#           'quoteTime' => '2016-10-26T16:00:01Z',
#           'sector' => 'Technology',
#           'tickerSymbol' => 'GOOG'
#         };


sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub get_basic_quote_as_text {
	my ($self, $symbol) = @_;

	my $data = $self->get_data($symbol);

	my $marketQuoteTime = str2time($data->{'quoteTime'});
	my $afterHoursQuoteTime = str2time($data->{'afterHoursQuoteTime'});

	if (defined($afterHoursQuoteTime) and $afterHoursQuoteTime > $marketQuoteTime) {
		return $self->get_printable_data(
			$symbol,
			[qw(tickerSymbol name price priceCurrency priceChange priceChangePercent afterHoursPrice priceCurrency afterHoursPriceChange afterHoursPriceChangePercent)],
			"%s (%s) %s %s (%s %s%%) *after hours*: %s %s %s (%s%%)",
			$data
		);
	} else {
		return $self->get_printable_data(
			$symbol,
			[qw(tickerSymbol name price priceCurrency priceChange priceChangePercent dataSource)],
			"%s (%s) %s %s (%s %s%%) [%s]",
			$data
		);
	}

}

sub get_printable_data {
	my ( $self, $symbol, $fields, $format, $data ) = @_;
	
	$data = $self->get_data($symbol) unless defined($data);
	my @values;
	foreach (@$fields) {
		my $v = $data->{$_};
		$v = "" unless defined($v);
		if (/change/i and $v =~ /^[\d\.\-\+]+$/) {
			$v = colorize($v);
		}
		push @values, $v;
	}
	return sprintf($format, @values);
}

sub get_data {
	my ( $self, $symbol ) = @_;

	my $tree = HTML::TreeBuilder::XPath->new_from_url($URL_BASE . $symbol);

	my %h; 

	my $metanodes = $tree->findnodes('//meta[@itemprop]');
	my $n;
	foreach $n ($metanodes->get_nodelist) {
		my ($k,$v);
		$v = $n->findvalue('./@content');
		$k = $n->findvalue('./@itemprop');
		$h{$k} = $v;
	}

	$h{sector} = $tree->findvalue('//a[@id="sector"]');

	my $rownodes = $tree->findnodes('//table[@class="snap-data"]/tr');
	foreach $n ($rownodes->get_nodelist) {
		my ($k,$v);
		$v = $n->findvalue('./td[@class="val"]');
		$k = $n->findvalue('./td[@class="key"]/@data-snapfield');
		$k =~ s/\s+$//;
		$v =~ s/\s+$//;
		$h{$k} = $v;
	}
	return \%h;
}

sub colorize {
	my ($string) = @_;

	if ($string !~ /^[\-+]/) {
		$string = "+$string";
	}	
	$string = String::IRC->new($string);
	if ($string =~ /^\-/) {
		$string->red;
	} else {
		$string->green;
	}
	return $string;
}

sub detail : GlobalRegEx('^stockrep (.+)$') {
	my ( $self, $message, $captures ) = @_;
	
	my @stocks = split /[\s,+]/, $captures->[0];
	my @fields = ("tickerSymbol", "name", "range_52week", "market_cap", "latest_dividend-dividend_yield", "vol_and_avg", "pe_ratio");
	my @results = map { $self->get_printable_data($_, \@fields, "%s (%s): 52wk %s -- Mkt cap %s -- Div/yield %s -- Vol/avg %s -- P/E %s") } @stocks;
	
	return (@results > 1 ? \@results : $results[0]);
}

sub indices : GlobalRegEx('^market$') {
	my ( $self, $message, $captures ) = @_;

	return $self->parse_message(undef, ["^dji ^inx"]);
}

sub parse_message : CommandRegEx('(.+)') {
	my ( $self, $message, $captures ) = @_;
	
	my @stocks = split /[\s,]+/, $captures->[0];
	  
	my @results = map { $self->get_basic_quote_as_text($_) } @stocks;	

	if (!@results) {
		return "I couldn't find anything for " . (join ', ', @stocks);
	}

	return (@results > 1 ? \@results : $results[0]);
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

Whatbot::Command::Market - Check the stock market using the Yahoo API

=head1 DESCRIPTION

Whatbot::Command::Market provides methods to check the result of a ticker,
fund, or index.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
