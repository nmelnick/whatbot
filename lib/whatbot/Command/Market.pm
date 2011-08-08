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

use XML::Simple qw(XMLin);
use String::IRC; # for colors!
use LWP::UserAgent ();

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
		my @formatfields = grep {$_ ne 'company'} @$fields;
		
		$format = "%s";
		if (@formatfields != @$fields) {
			$format .= " (%s)";
		}
		$format .=  (" %s" x @formatfields);
	}
	
	my @out;
	
	foreach my $symbol (@$stocks) {
		my $response = $self->ua->get("http://www.google.com/ig/api?stock=$symbol");
		
		if (! $response->is_success) {
			push @out, "got " . $response->code . " for $symbol";
			next;
		}

		my $info = eval { XMLin($response->decoded_content, ValueAttr => [ 'data' ] ) };
		if (my $err = $@) {
			$self->log->error("Decoding Google XML response for $symbol: $err");
			push @out, "error decoding XML for $symbol";
			next;
		}

		if (!defined($info->{finance})) {
			$self->log->error("No finance element in Google XML response for $symbol");
			push @out, "weird XML for $symbol";
			next;
		}

		$info = $info->{finance};
		
		my %data;
		
		foreach my $field (@$fields) {
			my $value = $info->{$field};
			
			if ($field eq "perc_change") {
				$value = colorize("$value%");
			} elsif ($field eq "change") {
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

	return "google doesn't do currency :(";
	
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
	
	my $detail_fields = [qw(company high low volume avg_volume)];
	my $format = "%s - today's hi %s - lo %s - vol %s (avg %s)";
	
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
	
	my $results = $self->process(\@stocks, [qw(company last perc_change change)]);
	
	if (!$results) {
		return "I couldn't find anything for $target.";
	}

	return $results;
}

1;

