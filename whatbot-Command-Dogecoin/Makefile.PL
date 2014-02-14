use inc::Module::Install;

# Define metadata
name     'whatbot-Command-Dogecoin';
all_from 'lib/whatbot/Command/Dogecoin.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'whatbot'                   => 0.12;
requires      'whatbot::Command::Bitcoin' => 0;
requires      'Moose'                     => 2.04;
requires      'namespace::autoclean'      => 0;
test_requires 'Test::More'                => 0;

WriteAll;
