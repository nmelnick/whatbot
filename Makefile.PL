use inc::Module::Install;

# Define metadata
name         'Whatbot';
all_from     'lib/Whatbot.pm';
author       'Nicholas Melnick <nick@abstractwankery.com>';
license      'perl';
perl_version '5.016';
provides 
  'Whatbot' => {
    'file' => 'lib/Whatbot.pm',
  },
  'Whatbot::Command' => {
    'file' => 'lib/Whatbot/Command.pm',
  }
;

# Specific dependencies
requires 'Alt::Devel::CallParser::ButWorking' => 0;

requires 'Algorithm::Backoff::Exponential' => 0;
requires 'AnyEvent'                        => 0;
requires 'AnyEvent::IRC'                   => 0;
requires 'AnyEvent::HTTPD'                 => 0;
requires 'AnyEvent::HTTP::LWP::UserAgent'  => 0;
requires 'AnyEvent::ReadLine::Gnu'         => 0;
requires 'AnyEvent::WebSocket::Client'     => 0;
requires 'Class::Inspector'                => 0;
requires 'Class::Load'                     => 0;
requires 'DateTime::Format::Natural'       => 0;
requires 'DBI'                             => 0;
requires 'DBD::SQLite'                     => 0;
requires 'Devel::StackTrace'               => 0;
requires 'Digest::SHA1'                    => 0;
requires 'EV'                              => 0;
requires 'Geo::Coder::OSM'                 => 0;
requires 'HTTP::Cookies'                   => 0;
requires 'HTML::Entities'                  => 0;
requires 'HTTP::Request'                   => 0;
requires 'HTML::Element'                   => 0;
requires 'HTML::Strip'                     => 0;
requires 'HTML::TreeBuilder'               => 0;
requires 'Image::Size'                     => 0;
requires 'IO::Socket::SSL'                 => 0;
requires 'JSON::XS'                        => 3.01;
requires 'LWP::Protocol::https'            => 0;
requires 'LWP::UserAgent'                  => 0;
requires 'Lingua::EN::Sentence'            => 0;
requires 'Math::Expression'                => 0;
requires 'Math::Units'                     => 0;
requires 'Module::Pluggable'               => 3.9;
requires 'Mojo::DOM'                       => 0;
requires 'Moose'                           => 2.04;
requires 'Moops'                           => 0.034;
requires 'MooX::HandlesVia'                => 0;
requires 'Number::Format'                  => 0;
requires 'Template'                        => 0;
requires 'Term::ReadLine::Gnu'             => 0;
requires 'Try::Tiny'                       => 0;
requires 'URI::Encode'                     => 0;
requires 'URI::Escape'                     => 0;
requires 'WWW::Mechanize'                  => 0;
requires 'WWW::Mechanize::GZip'            => 0;
requires 'XML::Simple'                     => 0;

requires 'AnyEvent::Discord'               => 0.7;
requires 'AnyEvent::SlackRTM'              => 1.1;
requires 'AnyEvent::XMPP'                  => 0;
requires 'Acme::LOLCAT'                    => 0;
requires 'Convert::Temperature'            => 0;
requires 'Math::Trig'                      => 0;
requires 'MooX::HandlesVia'                => 0;
requires 'Net::Telnet'                     => 0;
requires 'XML::Twig'                       => 0;

test_requires 'Test::More'                 => 0;

install_script 'bin/whatbot';

WriteAll;
