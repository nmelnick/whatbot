use inc::Module::Install;

# Define metadata
name     'Whatbot-IO-Slack';
all_from 'lib/Whatbot/IO/Slack.pm';
author   'Nick Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires      'Whatbot'              => 0.13;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'Method::Signatures'   => 20130505;
requires      'MooseX::Declare'      => 0.35;
requires      'JSON::XS'             => 3.01;
requires      'AnyEvent::SlackRTM'   => 0.152750;
test_requires 'Test::More'           => 0;

WriteAll;
