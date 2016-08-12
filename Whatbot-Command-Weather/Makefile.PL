use inc::Module::Install;

# Define metadata
name     'Whatbot-Command-Weather';
all_from 'lib/Whatbot/Command/Weather.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'Whatbot'              => 0.2;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'LWP::UserAgent'       => 0;
requires      'JSON::XS'             => 0;
requires      'Convert::Temperature' => 0;
requires      'Method::Signatures'   => 20130505;
requires      'Module::Pluggable'    => 3.9;
requires      'Try::Tiny'            => 0;
test_requires 'Test::More'           => 0;
test_requires 'Test::Exception'      => 0;

WriteAll;
