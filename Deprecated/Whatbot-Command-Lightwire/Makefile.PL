use inc::Module::Install;

# Define metadata
name     'Whatbot-Command-Lightwire';
all_from 'lib/Whatbot/Command/Lightwire.pm';
author   'Michael Gillis <michael@uken.com>';
license  'perl';

# Specific dependencies
requires      'Whatbot'              => 0.12;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'HTML::Entities'       => 0;
requires      'HTML::Strip'          => 0;
requires      'Method::Signatures'   => 20130505;
requires      'MooseX::Declare'      => 0.35;
requires      'URI::Escape'          => 0;
test_requires 'Test::More'           => 0;

WriteAll;
