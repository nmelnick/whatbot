#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use AnyEvent;
use Test::More tests => 9;

use Whatbot::Test;
use_ok( 'Whatbot::Database::Table::URL', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

my $url = Whatbot::Database::Table::URL->new();
ok( $url, 'Object created' );

{
	package Whatbot::Test::Response;
	sub new {
		my $self = {};
		return bless($self);
	}
	sub header {}
	sub content {
		return q{<!DOCTYPE html> <html lang="en" data-scribe-reduced-action-queue="true"> <head></head> <body class="three-col logged-out user-style-BirdsThoCo PermalinkPage" data-fouc-class-names="swift-loading" dir="ltr"> <div class="tweet permalink-tweet js-actionable-user js-actionable-tweet js-original-tweet has-cards with-social-proof has-content js-initial-focus " data-associated-tweet-id="800511501622620160" data-tweet-id="800511501622620160" data-item-id="800511501622620160" data-permalink-path="/BirdsThoCo/status/800511501622620160" data-tweet-nonce="800511501622620160-772e28fa-e3b3-48e6-b1c6-a98a3b064ce0" data-screen-name="BirdsThoCo" data-name="Birds tho" data-user-id="2452279423" data-you-follow="false" data-follows-you="false" data-you-block="false" data-disclosure-type="" data-has-cards="true" tabindex="0" > <p class="TweetTextSize TweetTextSize--26px js-tweet-text tweet-text" lang="en" data-aria-label-part="0">ʸᵉᵃʰ ᶜᵃᶰ ᴵ ᵍᵉᵗ ᵘʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰ</p> </div> </body> </html>};
	}
}
my $response = Whatbot::Test::Response->new();
my $result = $url->parse_url_content( 'https://twitter.com/status/800511501622620160', $response );
is( $result, '@BirdsThoCo: ʸᵉᵃʰ ᶜᵃᶰ ᴵ ᵍᵉᵗ ᵘʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰʰ', 'utf-8 twitter handling' );

my $cv = AnyEvent->condvar;

$cv->begin;
$url->retrieve_url_async(
	'https://pbs.twimg.com/profile_images/19056662/Hal-9000.jpg',
	sub {
		my ($title) = @_;
		ok( $title, 'Retrieve URL' );
		ok( $title =~ /jpg/i, $title );
		$cv->end;
	}
);

$cv->begin;
$url->retrieve_url_async(
	'https://twitter.com/nrmelnick/status/418564482131300352',
	sub {
		my ($title) = @_;
		ok( $title, 'Retrieve Twitter URL' );
		$title =~ s/\@\s*/@/g;
		like( $title,  qr/\@nrmelnick: \@mk_gillis BASE THIS/, $title );
		$cv->end;
	}
);

$cv->begin;
$url->retrieve_url_async(
	'http://www.google.com/asoeifmaorign',
	sub {
		my ($title) = @_;
		ok( $title, '404 will output something' );
		$cv->end;
	}
);

ok( $url->show_failures, 'Show failures by default' );

$cv->recv;

done_testing();
