use inc::Module::Install;

# Define metadata
name     'Whatbot';
all_from 'lib/Whatbot.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';
provides 
	'Whatbot' => {
		'file' => 'lib/Whatbot.pm',
	},
	'Whatbot::Command' => {
		'file' => 'lib/Whatbot/Command.pm',
	}
;

# Specific dependencies
requires       'AnyEvent'                            => 0;
requires       'AnyEvent::IRC'                       => 0;
requires       'AnyEvent::HTTPD'                     => 0;
requires       'Class::Inspector'                    => 0;
requires       'Class::Load'                         => 0;
requires       'Crypt::SSLeay'                       => 0;
requires       'DateTime::Format::Natural'           => 0;
requires       'DBI'                                 => 0;
requires       'DBD::SQLite'                         => 0;
requires       'Digest::SHA1'                        => 0;
requires       'EV'                                  => 0;
requires       'HTTP::Cookies'                       => 0;
requires       'HTML::Entities'                      => 0;
requires       'HTTP::Request'                       => 0;
requires       'HTML::Strip'                         => 0;
requires       'Image::Size'                         => 0;
requires       'IO::Socket::SSL'                     => 0;
requires       'JSON::XS'                            => 0;
requires       'Lingua::EN::Sentence'                => 0;
requires       'Math::Expression'                    => 0;
requires       'Math::Units'                         => 0;
requires       'Method::Signatures'                  => 20130505;
requires       'Module::Pluggable'                   => 3.9;
requires       'Mojo::DOM'                           => 0;
requires       'Moose'                               => 2.04;
requires       'MooseX::Declare'                     => 0.35;
requires       'MooseX::Singleton'                   => 0.29;
requires       'Number::Format'                      => 0;
requires       'Template'                            => 0;
requires       'URI::Encode'                         => 0;
requires       'URI::Escape'                         => 0;
requires       'WWW::Mechanize'                      => 0;
requires       'WWW::Mechanize::GZip'                => 0;
requires       'XML::Simple'                         => 0;

test_requires  'Test::More'                          => 0;

install_script 'bin/whatbot';

WriteAll;
