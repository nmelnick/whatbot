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

our $VERSION = '0.1';

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

my $SOURCE_NAME = 'Yahoo! Finance';

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	$self->ua->timeout(15);
}

sub process {
	my ( $self, $stocks, $fields, $format ) = @_;
	
	unless ($format) {
		$format = join( ' ', ('%s') x @$fields );
	}
	
	my @out;
	
	foreach my $symbol (@$stocks) {
		my $output = $self->_retrieve_yql( $symbol, $fields, $format );
		if ( not $output or $output =~ /weird XML/ ) {
			$output = $self->_retrieve_yahoo_scrape( $symbol, $fields, $format );
		}

		if ($output) {
			push( @out, $output );
		}
	}
	
	return join( ' || ', @out );
}

sub _retrieve_yql {
	my ( $self, $symbol, $fields, $format ) = @_;

	my @out;

	my $response = $self->ua->get(
		'http://query.yahooapis.com/v1/public/yql?'
		. 'q=select%20*%20from%20yahoo.finance.quotes%20where%20symbol%20in%20(%22'
	    . $symbol . '%22)&env=store://datatables.org/alltableswithkeys'
	);
	
	unless ( $response->is_success ) {
		return "got " . $response->code . " for $symbol";
	}

	my $info = eval { XMLin( $response->decoded_content, SuppressEmpty => 1 ) };
	if ( my $err = $@ ) {
		$self->log->error("Decoding $SOURCE_NAME response for $symbol: $err");
		return "error decoding XML for $symbol";
	}
	
	unless ( defined($info->{results}->{quote}) ) {
		# $self->log->error("No quote element in $SOURCE_NAME response for $symbol");
		return "weird XML for $symbol";
	}

	$info = $info->{results}->{quote};

	if ( $info->{ErrorIndicationreturnedforsymbolchangedinvalid} ) {
		my $val = $self->htmlstrip->parse($info->{ErrorIndicationreturnedforsymbolchangedinvalid});
		$self->htmlstrip->eof;
		return $val;
	}
	
	my %data;
	
	foreach my $field (@$fields) {
		my $value;
		if ($field =~ /^(\w+)\[(\d+)\]$/) {
			$value = ( split(/ +/,$info->{$1}) )[$2];
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
	
	return sprintf( $format, map { $data{$_} } @$fields );
}

sub _retrieve_yahoo_scrape {
	my ( $self, $symbol, $fields, $format ) = @_;

	$symbol = uc($symbol);

	my @out;

	my $response = $self->ua->get(
		'http://finance.yahoo.com/q?s=' . $symbol
	);
	
	unless ( $response->is_success ) {
		return "got " . $response->code . " for $symbol";
	}

	my %data = (
		'Symbol' => $symbol,
	);

	my $content = $response->decoded_content();

	# Name
	if ( $content =~ /<div class="title"><h2>(.*?)\(/ ) {
		$data{'Name'} = $1;
	}

	# PreviousClose
	if ( $content =~ /Prev Close:<\/th><td class="yfnc_tabledata1">([\d,\.]+)</ ) {
		$data{'PreviousClose'} = $1;
		$data{'PreviousClose'} =~ s/,//g;
	}

	# ChangeRealtime / ChangePercentRealtime
	if ( $content =~ /<span id="yfs_c10_[^"]+"><img.*?alt="(\w+)">\s*([\d,\.]+)<\/span><span id="yfs_p20_[^"]+">\(([\d,\.]+%)\)<\/span>/ ) {
		$data{'ChangeRealtime'} = colorize( ( $1 eq 'Down' ? '-' : '+' ) . $2 );
		$data{'ChangePercentRealtime'} = colorize( ( $1 eq 'Down' ? '-' : '+' ) . $3 );
	}

	# LastTradeRealtimeWithTime
	if ( $content =~ /<span class="time_rtq_ticker"><span id="yfs_l10_[^"]+">([\d,\.]+)<\/span><\/span>/ ) {
		$data{'LastTradeRealtimeWithTime'} = $1;
		$data{'LastTradeRealtimeWithTime'} =~ s/,//g;
	}

	unless (%data) {
		return 'unable to scrape for ' . $symbol;
	}
	
	return sprintf( $format, map { ( $data{$_} or '' ) } @$fields );
}

sub colorize {
	my ($string) = @_;
	
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

	my $results = $self->process([qw(^DJI ^GSPC ^IXIC ^GSPTSE)], [qw(Name[0] LastTradeRealtimeWithTime[2] ChangeRealtime ChangePercentRealtime[2])], "%s %s %s (%s)");
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

=pod

=head1 NAME

whatbot::Command::Market - Check the stock market using the Yahoo API

=head1 DESCRIPTION

whatbot::Command::Market provides methods to check the result of a ticker,
fund, or index.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
