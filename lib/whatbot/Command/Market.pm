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

use Finance::Quote;
use String::IRC; # for colors!
use LWP::UserAgent ();

has 'quote' => (
	is		=> 'ro',
	isa		=> 'Finance::Quote',
	default => sub { Finance::Quote->new; }
);

has 'ua' => (
	is		=> 'ro',
	isa		=> 'LWP::UserAgent',
	default => sub { LWP::UserAgent->new; }
);

has 'default_exchange' => (
	is		=> 'ro',
	isa		=> 'Str',
	default => 'nyse'
);

my $SEARCH_URL = "http://finance.yahoo.com/search?s=!repl!&b=1&v=s";
my $SEARCH_ROW_RE = qr!<tr bgcolor="ffffff">(.+?)</tr>!o;
my $SEARCH_COL_RE = qr!<a\s?.*?>(.+?)</a>!o;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	$self->quote->timeout(15);
	$self->quote->require_labels(qw/last p_change name net/);
	$self->ua->timeout(15);
}

sub search : GlobalRegEx('^stockfind (.+)$') {
	my ( $self, $message, $captures ) = @_;
	
	my $query = $captures->[0];
	
	my $url = $SEARCH_URL;
	$url =~ s/!repl!/$query/;
	
	my $response = $self->ua->get($url);
	
	unless ($response->is_success) {
		return ("Bad response from Yahoo! Finance: " . $response->status_line);
	}
	
	$_ = $response->content;
	foreach (split /\n/) {
		if (/$SEARCH_ROW_RE/) {
			$_ = $1;
			
			my @items = /$SEARCH_COL_RE/g;
			unless (@items == 4) {
				return ("Failed to parse columns from Yahoo! Finance result row: " . @items);
			}
            
			my ($company, $ticker, $sector, $industry) = @items;
			
			return "$query: $company ($ticker) -- $sector, $industry";
		}
	}
	return ("No companies found matching '$query'.");
}

sub process {
	my $self = shift;
	my $stocks = shift;
	my $fields = shift;
	my $format = shift;
	
	# default format is:
	# symbol (name) allotherfields spaceseparated
	if (!defined($format)) {
		my @formatfields = grep {$_ ne 'name'} @$fields;
		
		$format = "%s";
		if (@formatfields != @$fields) {
			$format .= " (%s)";
		}
		$format .=  (" %s" x @formatfields);
	}
	
	my $info = $self->quote->fetch($self->default_exchange, @$stocks);
	return undef unless $info;
	
	my @out;
	
	foreach my $symbol (@$stocks) {
		# this API is weird and involves commas in hash keys...
		# I guess this is the old way of doing things (?)
		
		if (! $info->{$symbol,"success"}) {
			push @out, $info->{$symbol,"errormsg"};
			next;
		}
		
		my %data;
		
		foreach my $field (@$fields) {
			my $value = $info->{$symbol,$field};
			
			if ($field eq "p_change") {
				$value = colorize("$value%");
			} elsif ($field eq "net" || $field eq "eps") {
				$value = colorize($value);
			}
			$data{$field} = $value;
		}
		
		push @out, sprintf($format, $symbol, map { $data{$_} } @$fields);
	}
	
	return join(" - ", @out);
}

sub colorize {
	my $string = shift;
	
	$string = String::IRC->new($string);
	if ($string =~ /^\-/) {
		$string->red;
	} else {
		$string->green;
	}
	return $string;
}

sub do_currency {
	my $self = shift;
	my $target = shift;
	
	my ( $to_cur, $from_cur ) = ( $target =~ m!^([a-z]+)/([a-z]+)$!io );
	
	if ( !defined($to_cur) || !defined($from_cur) ) {
		return "wtf is $target";
	}
	
	my $rate = $self->quote->currency($from_cur, $to_cur);
	
	if (!$rate) {
		return "I can't get a rate for $from_cur/$to_cur.";
	}
	return "1 $from_cur == $rate $to_cur";
}

sub detail : GlobalRegEx('^stockrep (.+)$') {
	my ( $self, $message, $captures ) = @_;
	
	my $target = $captures->[0];

	# from here on we're dealing with stocks
	my @stocks = map { s/\s//g; uc } split /,/, $target;
	
	my $detail_fields = [qw(name eps year_range div div_yield volume)];
	my $format = "%s - %s  eps %s - last 52w: %s - div %s (%s%y) - vol %s";
	
	my $results = $self->process(\@stocks, $detail_fields, $format);
	
	if (!$results) {
		return "I couldn't find anything for $target.";
	}
	
	return $results;
}

sub parse_message : CommandRegEx('(.+)') {
	my ( $self, $message, $captures ) = @_;
	
	my $target = $captures->[0];
	
	if ( $target =~ m!/!o ) {
		return $self->do_currency($target);
	}
	 
	# from here on we're dealing with stocks
	my @stocks = map { s/\s//g; uc } split /,/, $target;
	
	my $results = $self->process(\@stocks, [qw(name last p_change net)]);
	
	if (!$results) {
		return "I couldn't find anything for $target.";
	}

	return $results;
}

1;

