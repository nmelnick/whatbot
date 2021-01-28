#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Whatbot::Test;

{
	# "mock" AnyEvent::SlackRTM
	package AnyEvent::Discord;
	my $lastref;
	sub send {
		my ($self, $ref) = @_;
		$lastref = $ref;
		return;
	}

	sub lastref {
		return $lastref;
	}
}

use_ok( 'Whatbot::IO::Discord', 'Load module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

# Prep
my $discord = Whatbot::IO::Discord->new({
	'my_config' => {
		'token' => 'deadbeef',
	},
	'handle'    => AnyEvent::Discord->new({ token => 'deadbeef' }),
});
$discord->handle->{users} = {
  'ufoobar' => 'userbar',
};
$discord->handle->{channels} = {
  'cfoobar' => 'channelbar',
};

$discord->discord_name('example');
is( $discord->name, 'Discord_example', 'discord_name' );

done_testing();

1;
