#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'whatbot' ) || print "Bail out!\n";
}

diag( "Testing whatbot $whatbot::VERSION, Perl $], $^X" );
