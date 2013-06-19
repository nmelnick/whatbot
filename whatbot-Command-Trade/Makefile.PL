use inc::Module::Install;

# Define metadata
name     'whatbot-Command-Trade';
all_from 'lib/whatbot/Command/Trade.pm';
author   'Michael Gillis <michael@uken.com>';
license  'perl';

# Specific dependencies
requires      'whatbot'              => 0;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'HTML::Entities'       => 0;
requires      'HTML::Strip'          => 0;
requires      'URI::Escape'          => 0;
test_requires 'Test::More'           => 0;

WriteAll;
