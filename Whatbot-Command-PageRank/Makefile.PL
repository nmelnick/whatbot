use inc::Module::Install;

# Define metadata
name     'Whatbot-Command-PageRank';
all_from 'lib/Whatbot/Command/PageRank.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'Whatbot'               => 0.12;
requires      'Moose'                 => 2.04;
requires      'namespace::autoclean'  => 0;
requires      'WWW::Google::PageRank' => 0;
test_requires 'Test::More'            => 0;

WriteAll;
