###########################################################################
# whatbot/Command/eBay.pm
###########################################################################
# so what would one of those cost anyway
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::eBay;
use Moose;
BEGIN { extends 'whatbot::Command'; }

use HTTP::Request ();
use HTTP::Headers ();
use LWP::UserAgent ();
use XML::Simple qw(XMLin);

has 'ua'            => ( is => 'ro', isa => 'LWP::UserAgent', default => sub { new LWP::UserAgent; } );
has 'lasturl'       => ( is => 'rw', isa => 'Maybe[Str]' );
has 'lastitemid'    => ( is => 'rw', isa => 'Maybe[Str]');
has 'lastcategory'  => ( is => 'rw', isa => 'Maybe[Str]' );

my $EBAY_HEADERS = HTTP::Headers->new(
    'X-EBAY-API-SITEID'            => 0, # United States
    'X-EBAY-API-DEV-NAME'          => 'd19a2203-7464-4793-a78d-de087a6c0da8',
    'X-EBAY-API-APP-NAME'          => 'WhatCo652-e965-4384-8276-7f65a38a26e',
    'X-EBAY-API-CERT-NAME'         => 'eb7db469-57bf-4efd-9074-1e1c219e5e0c',
    'X-EBAY-API-VERSION'           => 515,
    'X-EBAY-API-REQUEST-ENCODING'  => 'XML',
    'Content-Type'                 => 'text/xml;charset=utf-8',
);

my $EBAY_URL = 'http://open.api.ebay.com/shopping?';

my @IGNORE_KEYS = (
    'Make', 'Model', # already in the title
    'Seller guarantee', 'Deposit type', 'Limited warranty',
    'VIN Number', 'Warranty', 'Vehicle Identification Number (VIN)',
    'Purchase protection', 'Search year', 'Title', 'VIN  Number',
    'Brand', 'Computed RE Message',
);

my @SELF_DESCRIPTIVE = (
    'Fuel type', 'Condition', 'Transmission',
    'Year', 'Body type', 'Operating System', 'Processor Speed',
    'Hard Drive Capacity', 'Processor Type',
);

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	$self->ua->agent('Mozilla/5.0');
}

sub parse_message : CommandRegEx('(.+)') {
	my ( $self, $message, $captures ) = @_;

    if ($captures) {
	    my $query = $captures->[0];
	    return 'what' unless $query;

        if ( $query =~ /^url$/i ) {
            my $url = $self->lasturl;
            return 'no last url saved' unless ( defined($url) );
            return $message->from . ': ' . $url;
        }
        elsif ( $query =~ /^details?$/i ) {
            my $id = $self->lastitemid;
            return 'no last item' unless ( defined($id) );
            return $self->item_detail($id);
        }
        elsif ( $query =~ /^category$/i ) {
            my $cat = $self->lastcategory;
            return 'no last category' unless ( defined($cat) );
            return $message->from . ': ' . $cat;
        }

	    return $self->find_item($query);
    }
}

sub do_query {
    my ( $self, $callname, $xml ) = @_;
    
    my $req = HTTP::Request->new('POST', $EBAY_URL, $EBAY_HEADERS, $xml);
    $req->header('X-EBAY-API-CALL-NAME', $callname);
    warn $req->as_string;

    my $response = $self->ua->request($req);
    unless ($response) {
       return('No response from LWP::UserAgent');
    }
    unless ( $response->is_success ) {
        return($response->status_line);
    }
    my $content = $response->content;

    my $result = eval {
        XMLin($content,
            #'KeyAttr' => {'NameValueList' => 'Name'},
            'ForceArray' => [ 'NameValueList' ],
            'GroupTags' => {
                'ItemSpecifics' => 'NameValueList'
            }
        );
    };
    if ( $@ or !defined($result) ) {
        return "Couldn't parse XML: $@" if ($@);
        return("Couldn't parse XML");
    }

   if ( $result->{'Errors'} ) {
       my @errors;
       foreach my $err (%{ $result->{'Errors'} }) {
           push @errors, $err->{'LongMessage'};
       }
       return( join('; ', @errors) );
   }
   else {
       return $result;
   }
}

sub item_detail {
    my ( $self, $id ) = @_;

    my $xml = qq{<?xml version="1.0" encoding="utf-8"?>
<GetSingleItemRequest xmlns="urn:ebay:apis:eBLBase_components">
<ItemID>$id</ItemID>
<IncludeSelector>Details,ItemSpecifics</IncludeSelector>
</GetSingleItemRequest>};

    my $result = $self->do_query('GetSingleItem', $xml);

    if ( !ref($result) ) {
       return("Error: $result");
    }

    unless ( $result->{'Item'} ) {
       return("No detail available for Item #$id");
    }

    my $item = $result->{'Item'};

    my $subtitle = '';

    my @specifics;
    if ( $item->{'ItemSpecifics'} ) {
        foreach my $nv (@{ $item->{'ItemSpecifics'} }) {
            my $value = $nv->{'Value'};
            my $key   = $nv->{'Name'};

            next if ( $key =~ /SIFFTAS/ ); # eBay-internal

            next if ( !defined($value) or ref($value) eq 'HASH' ); 
            next if ( $key eq $value ); # I'm sure we don't care then

            if ( $key eq 'Sub title' ) {
                $subtitle = $value;
                next;
            }

            next if ( grep { $_ eq $key } @IGNORE_KEYS );

            if ( ref($value) eq 'ARRAY' ) {
                $value = join(', ', @$value);
            } else {
                $value =~ substr($value, 0, 4) if $key eq 'Year'; # weird zeroes
                next if ( $value eq '-' );
            }

            if ( grep { $_ eq $key } @SELF_DESCRIPTIVE ) {
                next if ( $value eq 'Gasoline' );
                push( @specifics, $value );
            }
            else {
                next if ( length($key) > 20 ); # shut up
                push( @specifics, "$key: $value" );
            }
        }
    }

    my $specs = join( ', ', @specifics );
    my $location = $item->{'Location'};

    return ( $subtitle ? "$subtitle - " : '' ) . "$specs (Loc: $location)";
}

sub find_item {
    my ( $self, $query ) = @_;

    my $xml = qq{<?xml version="1.0" encoding="utf-8"?>
<FindItemsRequest xmlns="urn:ebay:apis:eBLBase_components">
    <QueryKeywords>$query</QueryKeywords>
    <MaxEntries>1</MaxEntries>
</FindItemsRequest>};

    my $result = $self->do_query('FindItems', $xml);

    if ( !ref($result) ) {
       return 'Error: ' . $result;
    }

    unless ( $result->{'Item'} ) {
        warn Data::Dumper::Dumper($result);
        return 'No eBay results for: ' . $query;
    }

    my $item = $result->{'Item'};
    my $title = $item->{'Title'};
    $title =~ s/ : / /g;

    my $url   = $item->{'ViewItemURLForNaturalSearch'};
    my $bidcount = $item->{'BidCount'};
    my $type  = $item->{'ListingType'};
    my $timeleft = $item->{'TimeLeft'};
    if ( $timeleft eq 'PT0S' ) {
       $timeleft = 'Ended';
    } else {
       local $_ = $timeleft;
       s/[PT]//ig; # more legible without this
       ($_) = /^(\d+\w)/;
       $timeleft = lc($_) . ' left';
    }

    my $buyitnow = _hash_to_price($item->{'ConvertedBuyItNowPrice'});
    my $price    = _hash_to_price($item->{'ConvertedCurrentPrice'});

    my @categories = split( /:/, $item->{'PrimaryCategoryName'} );

    my $str = "$title -- $price $timeleft"; 
    $str .= " ($type)" if ( $type ne 'Chinese' );
    $str .= ", $bidcount bids" if ( defined($bidcount) );
    $str .= " (BuyItNow: $buyitnow)" if ($buyitnow);

    $self->lasturl($url);
    $self->lastitemid( $item->{'ItemID'} );
    $self->lastcategory( $item->{'PrimaryCategoryName'} );
    return $str;
}

sub _hash_to_price {
    my ( $pricehash ) = @_;

    return undef unless ( defined($pricehash) and ref($pricehash) eq 'HASH' );

    my $curr = $pricehash->{'currencyID'};
    my $price = $pricehash->{'content'};
    my $symbol = '';
    my $precision = 2;

    if ( $curr eq 'USD' or $curr eq 'CAD' or $curr eq 'AUD' or $curr eq 'NZD' ) {
        $symbol = '$';
    } elsif ( $curr eq 'EUR' ) {
        $symbol = '€';
    } elsif ( $curr eq 'GBP' ) {
        $symbol = '£';
    } elsif ( $curr eq 'JPY' or $curr eq 'CNY' or $curr eq 'RMB' ) {
        $symbol = '¥';
        $precision = 0;
    } else {
        $precision = -1; # don't round
    }

    if ( $precision >= 0 ) {
        $price = sprintf( "%.0${'precision'}f", $price );
    }

    return $curr . $symbol . $price;
}

1;
