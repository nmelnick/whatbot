use inc::Module::Install;

# Define metadata
name     'whatbot';
all_from 'lib/whatbot.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';
provides 
	'whatbot' => {
		'file' => 'lib/whatbot.pm'
	},
	'whatbot::Command' => {
		'file' => 'lib/whatbot/Command.pm'
	},
	'whatbot::Command' => {
		'file' => 'lib/whatbot/Component.pm'
	},
	'whatbot::Test' => {
		'file' => 'lib/whatbot/Test.pm'
	},
	'whatbot::Types' => {
		'file' => 'lib/whatbot/Types.pm'
	}
;

# Specific dependencies
requires       'AnyEvent'                  => 0;
requires       'AnyEvent::IRC'             => 0;
requires       'AnyEvent::HTTPD'           => 0;
requires       'Class::Inspector'          => 0;
requires       'Class::Load'               => 0;
requires       'DBI'                       => 0;
requires       'EV'                        => 0;
requires       'HTTP::Cookies'             => 0;
requires       'HTML::Entities'            => 0;
requires       'HTTP::Request'             => 0;
requires       'HTML::Strip'               => 0;
requires       'JSON::XS'                  => 0;
requires       'Module::Pluggable'         => 3.9;
requires       'Moose'                     => 2.04;
requires       'MooseX::Declare'           => 0.35;
requires       'Template'                  => 0;

recommends     'Acme::LOLCAT'              => 0;
recommends     'DateTime::Format::Natural' => 0;
recommends     'Image::Size'               => 0;
recommends     'Lingua::EN::Sentence'      => 0;
recommends     'Math::Expression'          => 0;
recommends     'Math::Trig'                => 0;
recommends     'Math::Units'               => 0;
recommends     'Net::OSCAR'                => 0;
recommends     'Net::Telnet'               => 0;
recommends     'URI::Escape'               => 0;

test_requires  'Test::More'                => 0;

install_script 'bin/whatbot';

WriteAll;
