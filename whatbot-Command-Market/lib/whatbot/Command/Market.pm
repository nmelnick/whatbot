###########################################################################
# whatbot/Command/Market.pm
###########################################################################
# grabs currency rates and stocks, for lols
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Market;
use Moose;
BEGIN { extends 'whatbot::Command' }
use namespace::autoclean;

use HTML::TreeBuilder::XPath;
use String::IRC; # for colors!

our $VERSION = '0.1';

my $URL_BASE = 'http://www.google.com/finance?q=';

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub get_printable_data {
	my ( $self, $symbol, $fields, $format ) = @_;
	
	my $data = $self->get_data($symbol);
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
		$k = $n->findvalue('./td[@class="key"]');
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
	my @fields = ("tickerSymbol", "name", "52 Week", "Mkt cap", "Div/yield", "Vol / Avg.", "P/E");
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
	  
	my @results = map { $self->get_printable_data($_, [qw(tickerSymbol name price priceCurrency priceChange priceChangePercent dataSource)], "%s (%s) %s %s (%s %s%%) [%s]") } @stocks;	

	if (!@results) {
		return "I couldn't find anything for " . (join ', ', @stocks);
	}

	return (@results > 1 ? \@results : $results[0]);
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

whatbot::Command::Market - Check the stock market using the Yahoo API

=head1 DESCRIPTION

whatbot::Command::Market provides methods to check the result of a ticker,
fund, or index.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
