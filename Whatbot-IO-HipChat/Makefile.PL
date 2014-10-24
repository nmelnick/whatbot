use inc::Module::Install;

# Define metadata
name     'Whatbot-IO-HipChat';
all_from 'lib/Whatbot/IO/HipChat.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'Whatbot'              => 0.12;
requires      'Whatbot::IO::Jabber'  => 0.2;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'Method::Signatures'   => 20130505;
requires      'MooseX::Declare'      => 0.35;
test_requires 'Test::More'           => 0;

WriteAll;
