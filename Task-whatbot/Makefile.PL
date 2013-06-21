use inc::Module::Install;

# Define metadata
name     'Task-whatbot';
all_from 'lib/Task/whatbot.pm';
author   'Nicholas Melnick <nick@abstractwankery.com>';
license  'perl';

# Specific dependencies
requires       'whatbot'                     => 0.12;
requires       'whatbot::Command::Blackjack' => 0.1;
requires       'whatbot::Command::Market'    => 0.1;
requires       'whatbot::Command::PageRank'  => 0.1;
requires       'whatbot::Command::Paste'     => 0.1;
requires       'whatbot::Command::Quote'     => 0.1;
requires       'whatbot::Command::RSS'       => 0.1;
requires       'whatbot::Command::Trade'     => 0.1;
requires       'whatbot::Command::Translate' => 0.1;
requires       'whatbot::Command::Weather'   => 0.1;
requires       'whatbot::IO::AIM'            => 0.1;

WriteAll;
