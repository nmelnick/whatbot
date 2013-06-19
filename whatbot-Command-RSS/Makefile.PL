use inc::Module::Install;

# Define metadata
name     'whatbot-Command-RSS';
all_from 'lib/whatbot/Command/RSS.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'whatbot'              => 0;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'Digest::MD5'          => 0;
requires      'LWP::UserAgent'       => 0;
requires      'XML::Simple'          => 0;
test_requires 'Test::More'           => 0;

WriteAll;
