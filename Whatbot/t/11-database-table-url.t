#!/usr/bin/env perl

use Test::More;

use Whatbot::Test;
use_ok( 'Whatbot::Database::Table::URL', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

my $url = Whatbot::Database::Table::URL->new();
ok( $url, 'Object created' );

my $title;
ok( $title = $url->retrieve_url('https://pbs.twimg.com/profile_images/19056662/Hal-9000.jpg'), 'Retrieve URL' );
ok( $title =~ /jpg/i, $title );
ok( $title = $url->retrieve_url("https://twitter.com/nrmelnick/status/418564482131300352"), "Retrieve Twitter URL" );
$title =~ s/\@\s*/@/g;
like( $title,  qr/\@nrmelnick: \@mk_gillis BASE THIS/, $title );

ok( $url->show_failures, 'Show failures by default' );
ok( $url->retrieve_url('http://www.google.com/asoeifmaorign'), '404 will output something' );
$url->config->{'commands'}->{'url'}->{'hide_failures'} = 1;
ok( ! $url->show_failures, 'Do not show failures with config setting' );
ok( ! $url->retrieve_url('http://www.google.com/asoeifmaorign'), '404 will not output anything' );

done_testing();
