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

use XML::Simple qw(XMLin);
use String::IRC; # for colors!
use LWP::UserAgent ();
use HTML::Entities qw(decode_entities);
use HTML::Strip;

has 'ua' => (
	is		=> 'ro',
	isa		=> 'LWP::UserAgent',
	default => sub { LWP::UserAgent->new; }
);

has 'htmlstrip' => (
	is 		=> 'ro',
	isa 	=> 'HTML::Strip',
	default	=> sub { HTML::Strip->new; }
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
	
	if (!defined($format)) {
		$format = join(" ", ("%s") x @$fields);
	}
	
	my @out;
	
	foreach my $symbol (@$stocks) {
		my $response = $self->ua->get('http://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22'
		 . $symbol . '%22)&env=store://datatables.org/alltableswithkeys');
		
		if (! $response->is_success) {
			push @out, "got " . $response->code . " for $symbol";
			next;
		}

		my $info = eval { XMLin($response->decoded_content, SuppressEmpty => 1) };
		if (my $err = $@) {
			$self->log->error("Decoding Google XML response for $symbol: $err");
			push @out, "error decoding XML for $symbol";
			next;
		}
		
		if (!defined($info->{results}->{quote})) {
			$self->log->error("No quote element in Google XML response for $symbol");
			push @out, "weird XML for $symbol";
			next;
		}

		$info = $info->{results}->{quote};

		if ($info->{ErrorIndicationreturnedforsymbolchangedinvalid} ne "") {
			push @out, $self->htmlstrip->parse($info->{ErrorIndicationreturnedforsymbolchangedinvalid});
			$self->htmlstrip->eof;
			next;
		}
		
		my %data;
		
		foreach my $field (@$fields) {
			my $value;
			if ($field =~ /^(\w+)\[(\d+)\]$/) {
				$value = (split(/ +/,$info->{$1}))[$2];
			} else {
				$value = $info->{$field};
			}

			$value =~ s|</?b>||g;
			$value =~ s|N/A - ||g;
			$value = decode_entities($value);
			
			if ( $field =~ /Change/ ) {
				if ($field =~ /Percent/) {
					$value = "$value";
				}
				$value = colorize($value);
			}
			$data{$field} = $value;
		}
		
		push @out, sprintf($format, map { $data{$_} } @$fields);
	}
	
	return join(" || ", @out);
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
	
	my $detail_fields = [qw(Name PreviousClose BidRealtime AskRealtime DaysLow DaysHigh YearLow YearHigh TwoHundreddayMovingAverage FiftydayMovingAverage)];
	my $format = "%s - prev close %s - bid %s / ask %s - day lo %s / hi %s - year lo %s / hi %s - ma 200d %s 50d %s";
	
	my $results = $self->process(\@stocks, $detail_fields, $format);
	
	if (!$results) {
		return "I couldn't find anything for $target.";
	}
	
	return $results;
}

sub indices : GlobalRegEx('^market$') {
	my ( $self, $message, $captures ) = @_;

	my $results = $self->process([qw(^GSPC ^IXIC ^GSPTSE)], [qw(Name[0] LastTradeRealtimeWithTime[2] ChangeRealtime ChangePercentRealtime[2])], "%s %s %s (%s)");
	return $results if $results;
}

sub parse_message : CommandRegEx('(.+)') {
	my ( $self, $message, $captures ) = @_;
	
	my $target = $captures->[0];
	
	if ( $target =~ m!/!o ) {
		return $self->do_currency($target);
	}
	 
	# from here on we're dealing with stocks
	my @stocks = map { s/\s//g; uc } split /,/, $target;
	
	my $results = $self->process(\@stocks, [qw(Symbol Name PreviousClose TickerTrend LastTradeRealtimeWithTime ChangeRealtime ChangePercentRealtime)], "%s %s %s %s %s %s (%s)");
	
	if (!$results) {
		return "I couldn't find anything for $target.";
	}

	return $results;
}

__PACKAGE__->meta->make_immutable;

1;

