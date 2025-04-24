#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

require_ok( 'Whatbot::Utility' );

my $some_unicode = 'ƅ Ɔ Ƈ ƈ Ɖ Ɗ Ƌ ƌ ƍ Ǝ Ə Ɛ Ƒ ƒ';
my $html_unicode = '<span><b>' . $some_unicode . '</b></span>';

is( Whatbot::Utility::html_strip($html_unicode), $some_unicode, 'Accurate strip with unicode' );

done_testing();

1;
