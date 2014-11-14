use inc::Module::Install;

# Define metadata
name     'Whatbot-Command-Quote';
all_from 'lib/Whatbot/Command/Quote.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'Whatbot'                    => 0.12;
requires      'Whatbot::Helper::Bootstrap' => 0;
requires      'Moose'                      => 2.04;
requires      'namespace::autoclean'       => 0;
requires      'HTML::Entities'             => 0;
requires      'Try::Tiny'                  => 0;
test_requires 'Test::More'                 => 0;

WriteAll;
