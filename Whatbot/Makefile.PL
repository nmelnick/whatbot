use inc::Module::Install;

# Define metadata
name         'Whatbot';
all_from     'lib/Whatbot.pm';
author       'Nicholas Melnick <nick@abstractwankery.com>';
license      'perl';
perl_version '5.014';
provides 
	'Whatbot' => {
		'file' => 'lib/Whatbot.pm',
	},
	'Whatbot::Command' => {
		'file' => 'lib/Whatbot/Command.pm',
	}
;

# Specific dependencies
requires       'AnyEvent'                       => 0;
requires       'AnyEvent::IRC'                  => 0;
requires       'AnyEvent::HTTPD'                => 0;
requires       'AnyEvent::HTTP::LWP::UserAgent' => 0;
requires       'AnyEvent::ReadLine::Gnu'        => 0;
requires       'Class::Inspector'               => 0;
requires       'Class::Load'                    => 0;
requires       'DateTime::Format::Natural'      => 0;
requires       'DBI'                            => 0;
requires       'DBD::SQLite'                    => 0;
requires       'Devel::StackTrace'              => 0;
requires       'Digest::SHA1'                   => 0;
requires       'EV'                             => 0;
requires       'HTTP::Cookies'                  => 0;
requires       'HTML::Entities'                 => 0;
requires       'HTTP::Request'                  => 0;
requires       'HTML::Strip'                    => 0;
requires       'Image::Size'                    => 0;
requires       'IO::Socket::SSL'                => 0;
requires       'JSON::XS'                       => 3.01;
requires       'LWP::Protocol::https'           => 0;
requires       'Lingua::EN::Sentence'           => 0;
requires       'Math::Expression'               => 0;
requires       'Math::Units'                    => 0;
requires       'Module::Pluggable'              => 3.9;
requires       'Mojo::DOM'                      => 0;
requires       'Moose'                          => 2.04;
requires       'Moops'                          => 0.034;
requires       'MooX::HandlesVia'               => 0;
requires       'Number::Format'                 => 0;
requires       'Template'                       => 0;
requires       'Try::Tiny'                      => 0;
requires       'URI::Encode'                    => 0;
requires       'URI::Escape'                    => 0;
requires       'WWW::Mechanize'                 => 0;
requires       'WWW::Mechanize::GZip'           => 0;
requires       'XML::Simple'                    => 0;

recommends     'AnyEvent::SlackRTM'             => 1.0;
recommends     'AnyEvent::XMPP'                 => 0;
recommends     'Acme::LOLCAT'                   => 0;
recommends     'Math::Trig'                     => 0;
recommends     'MooX::HandlesVia'               => 0;
recommends     'Net::Telnet'                    => 0;
recommends     'XML::Twig'                      => 0;

test_requires  'Test::More'                     => 0;

install_script 'bin/whatbot';

WriteAll;
