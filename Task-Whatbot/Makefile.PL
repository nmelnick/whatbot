use inc::Module::Install;

# Define metadata
name     'Task-Whatbot';
all_from 'lib/Task/Whatbot.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires       'Whatbot'                      => 0.13;
requires       'Whatbot::Command::Annoying'   => 0.1;
requires       'Whatbot::Command::Bitcoin'    => 0.1;
requires       'Whatbot::Command::Blackjack'  => 0.1;
requires       'Whatbot::Command::Dogecoin'   => 0.1;
requires       'Whatbot::Command::Excuse'     => 0.1;
requires       'Whatbot::Command::Market'     => 0.1;
requires       'Whatbot::Command::Nickometer' => 0.1;
requires       'Whatbot::Command::PageRank'   => 0.1;
requires       'Whatbot::Command::Paste'      => 0.1;
requires       'Whatbot::Command::Quote'      => 0.1;
requires       'Whatbot::Command::RSS'        => 0.1;
requires       'Whatbot::Command::Trade'      => 0.1;
requires       'Whatbot::Command::Weather'    => 0.2;
requires       'Whatbot::IO::AIM'             => 0.1;
requires       'Whatbot::IO::Jabber'          => 0.2;

WriteAll;
