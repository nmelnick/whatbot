#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;
use Whatbot::Helper::Bootstrap::Link;

sub test {
  ok( my $test = Test::Whatbot::Command::Role::BootstrapTemplate->new(), 'new' );

  like( $test->_navbar_template, qr/No commands found/, 'navbar no commands' );
  like( ${$test->combine_content(\'')}, qr/No commands found/, 'full no commands' );

  $test->add_menu_item(
    Whatbot::Helper::Bootstrap::Link->new({
      'title' => 'Example Menu!',
      'href'  => '#',
    })
  );

  like( $test->_navbar_template, qr/<a href="#">Example Menu!<\/a>/, 'navbar example menu' );
};

{
  package Test::Whatbot::Command::Role::BootstrapTemplate;
  use Moose;
  with 'Whatbot::Command::Role::BootstrapTemplate';

  1;
}

test();

done_testing();

