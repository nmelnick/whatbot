use inc::Module::Install;

# Define metadata
name     'whatbot-Command-Translate';
all_from 'lib/whatbot/Command/Translate.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'whatbot'              => 0.12;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'WWW::Babelfish'       => 0;
test_requires 'Test::More'           => 0;

WriteAll;
