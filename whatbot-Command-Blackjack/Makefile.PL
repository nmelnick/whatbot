use inc::Module::Install;

# Define metadata
name     'whatbot-Command-Blackjack';
all_from 'lib/whatbot/Command/Blackjack.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'whatbot'              => 0.12;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
test_requires 'Test::More'           => 0;

WriteAll;
