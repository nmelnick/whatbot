#!/usr/bin/env perl

use Test::More;

use whatbot::Test;
use_ok( 'whatbot::Database::Table::URL', 'Load Module' );

my $test = whatbot::Test->new();
my $base_component = $test->get_base_component();

my $url = whatbot::Database::Table::URL->new( base_component => $base_component );
ok( $url, 'Object created' );

my $title;
ok( $title = $url->retrieve_url('http://primates.ximian.com/~miguel/images/eclipse-mono.png'), 'Retrieve URL' );
ok( $title =~ /png/i, $title );
ok( $title = $url->retrieve_url("https://twitter.com/nrmelnick/status/418564482131300352"), "Retrieve Twitter URL" );
like( $title,  qr/\@nrmelnick: @ mk_gillis BASE THIS/, $title );

done_testing();
