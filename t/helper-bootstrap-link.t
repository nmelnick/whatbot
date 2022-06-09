#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 9;

use_ok( 'Whatbot::Helper::Bootstrap::Link', 'Load Module' );

ok( my $link = Whatbot::Helper::Bootstrap::Link->new(), 'new' );
is( $link->render(), '<a href=""></a>', 'empty link render' );

$link = Whatbot::Helper::Bootstrap::Link->new();
$link->title('Example title');
is( $link->render(), '<a href="">Example title</a>', 'has title empty href render' );

$link = Whatbot::Helper::Bootstrap::Link->new();
$link->href('#');
is( $link->render(), '<a href="#"></a>', 'empty title has href render' );

$link = Whatbot::Helper::Bootstrap::Link->new();
$link->title('Example title');
$link->href('#');
is( $link->render(), '<a href="#">Example title</a>', 'has title has href render' );

$link = Whatbot::Helper::Bootstrap::Link->new();
$link->title('Example title');
$link->href('#');
$link->class('foo');
is( $link->render(), '<a href="#" class="foo">Example title</a>', 'has title has href has class render' );

$link = Whatbot::Helper::Bootstrap::Link->new();
$link->title('Example title');
$link->href('#');
$link->class('foo');
$link->role('bar');
is( $link->render(), '<a href="#" class="foo" role="bar">Example title</a>', 'has title has href has class has role render' );

$link = Whatbot::Helper::Bootstrap::Link->new();
$link->title('Dropdown');
$link->href('#');
$link->add_dropdown_item( Whatbot::Helper::Bootstrap::Link->new( 'title' => 'Whee' ) );
is(
  $link->render(),
  '<div class="dropdown"><a href="#" class="dropdown-toggle" data-toggle="dropdown" id="dropdown-dropdown">Dropdown <span class="caret"></span></a><ul class="dropdown-menu" role="menu" aria-labelledby="dropdown-dropdown"><li role="presentation"><a href="" role="menuitem">Whee</a></li></ul></div>',
  'has dropdown render'
);

done_testing();
