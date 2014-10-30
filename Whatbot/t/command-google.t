#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;

use_ok( 'Whatbot::Command::Google', 'Load Module' );

my $test = Whatbot::Test->new();
$test->initialize_state();
$test->initialize_models();

ok( my $google = Whatbot::Command::Google->new({
	'my_config'      => {},
	'name'           => 'Google',
}), 'new' );
$google->register();

my $message = Whatbot::Message->new({ from => 'Test', to => 'context', content => '' });

my $response = $google->_search( 'whatbot sucks' );
ok( $response, 'search has response' );
ok( ref($response) eq 'ARRAY', 'response is array' );
like( $response->[0], qr/ \- /, 'title/desc has dash' );
like( $response->[1], qr/^http/, 'url is url' );

$response = $google->image( $message, [ 'the', 'count' ] );
ok( $response !~ /^Could not/, 'image contacted google' );
ok( $response =~ /^http/, 'responded with url' );

done_testing();

1;
