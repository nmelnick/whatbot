#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename;
use File::Find;
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $root_dir = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );
my $lib_dir = File::Spec->catdir( $root_dir, 'lib' );
my @modules;
find(
  sub {
    return if ( $File::Find::name !~ /\.pm\z/ );
    my $lib_dirre = $lib_dir;
    $lib_dirre =~ s/\//\\\//g;
    my $found = $File::Find::name;
    $found =~ s{^$lib_dirre/}{};
    $found =~ s{[/\\]}{::}g;
    $found =~ s/\.pm$//;
    # nothing to skip
    push( @modules, $found );
  },
  $lib_dir,
);

sub _find_scripts {
  my $dir = shift @_;

  my @found_scripts = ();
  find(
    sub {
      return unless (-f);
      my $found = $File::Find::name;
      # nothing to skip
      open( my $FH, '<', $_ ) or do {
        note( "Unable to open $found in ( $! ), skipping" );
        return;
      };
      my $shebang = <$FH>;
      return unless ( $shebang =~ /^#!.*?\bperl\b\s*$/ );
      push( @found_scripts, $found );
      close($FH);
    },
    File::Spec->catdir( $root_dir, $dir ),
  );

  return @found_scripts;
}

my @scripts;
do { push( @scripts, _find_scripts($_) ) if ( -d $_ ) }
  for qw{ bin script scripts };

my $plan = scalar(@modules) + scalar(@scripts);
$plan ? (plan tests => $plan) : (plan skip_all => "no tests to run");

{
  # fake home for cpan-testers
  local $ENV{HOME} = tempdir( CLEANUP => 1 );

  like( qx{ $^X -Ilib -e "require $_; print '$_ ok'" }, qr/^\s*$_ ok/s, "$_ loaded ok" )
    for ( sort @modules );

  SKIP: {
    eval "use Test::Script 1.05; 1;";
    skip "Test::Script needed to test script compilation", scalar(@scripts) if $@;
    foreach my $file ( @scripts ) {
      my $script = $file;
      $script =~ s!.*/!!;
      script_compiles( $file, "$script script compiles" );
    }
  }
  BAIL_OUT("Compilation failures") if !Test::More->builder->is_passing;
}
