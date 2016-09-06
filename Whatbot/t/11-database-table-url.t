#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use AnyEvent;
use Test::More tests => 8;

use Whatbot::Test;
use_ok( 'Whatbot::Database::Table::URL', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

my $url = Whatbot::Database::Table::URL->new();
ok( $url, 'Object created' );

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
