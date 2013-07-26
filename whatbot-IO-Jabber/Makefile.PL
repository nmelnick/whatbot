use inc::Module::Install;

# Define metadata
name     'whatbot-IO-Jabber';
all_from 'lib/whatbot/IO/Jabber.pm';
author   'Brian Phillips <bphillips@cpan.org>';
license  'perl';

# Specific dependencies
requires      'whatbot'              => 0.12;
requires      'Moose'                => 2.04;
requires      'namespace::autoclean' => 0;
requires      'Method::Signatures'   => 20130505;
requires      'MooseX::Declare'      => 0.35;
requires      'AnyEvent::XMPP'       => 0;
test_requires 'Test::More'           => 0;

WriteAll;
