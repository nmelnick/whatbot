use inc::Module::Install;

# Define metadata
name     'whatbot-Helper-Bootstrap';
all_from 'lib/whatbot/Helper/Bootstrap.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'whatbot'              => 0.12;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'HTML::Entities'       => 0;
requires      'URI::Encode'          => 0;
test_requires 'Test::More'           => 0;

WriteAll;
