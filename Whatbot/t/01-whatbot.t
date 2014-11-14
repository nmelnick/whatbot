#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd qw(realpath getcwd);
use FindBin;
use JSON::XS;

my $basedir = $FindBin::Bin;

use_ok( 'Whatbot', 'load' );

my $whatbot = Whatbot->new();

ok( $whatbot, 'new' );
is( ref($whatbot), 'Whatbot', 'blessed' );
ok( my $config = $whatbot->config( $basedir, $basedir . '/example.conf' ), 'config load' );
is( $config->config_hash->{'irrelevant'}, JSON::XS::true, 'config read' );

eval {
	$whatbot->report_error('Example');
};
like( $@, qr/^ERROR: Example/, 'report error' );

eval {
	$whatbot->report_error();
};
like( $@, qr/missing required argument/, 'missing error' );

done_testing();

1;
