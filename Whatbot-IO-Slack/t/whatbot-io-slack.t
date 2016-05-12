#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Whatbot::Test;

{
	package AnyEvent::SlackRTM;
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

use_ok( 'Whatbot::IO::Slack', 'Load module' );

my $test = Whatbot::Test->new();
$test->initialize_state();

eval {
	my $slack = Whatbot::IO::Slack->new({
		'my_config'      => {},
	});
};
like( $@, qr/IO\->Slack is missing an access token/, 'Error when missing token' );

# Prep
my $slack = Whatbot::IO::Slack->new({
	'my_config' => {
		'token' => 'deadbeef',
	},
	'handle'    => AnyEvent::SlackRTM->new(),
	'users'     => {
		'ufoobar' => 'userbar',
	},
	'channels'     => {
		'cfoobar' => 'channelbar',
	},
});

$slack->slack_name('example');
is( $slack->name, 'Slack_example', 'slack_name' );

# Messaging
my $message = {
	'user'    => 'ufoobar',
	'channel' => 'cfoobar',
	'text'    => 'example',
};
my $slack_message = $slack->_slack_message_to_message($message);
is( ref($slack_message), 'Whatbot::Message', '_slack_message_to_message is Whatbot::Message' );
is( $slack_message->from, 'userbar', '_slack_message_to_message has from user' );
is( $slack_message->to, 'channelbar', '_slack_message_to_message has to channel' );
is( $slack_message->content, 'example', '_slack_message_to_message has content');

$message->{'text'} = 'well, then, <@foo>';
$slack_message = $slack->_slack_message_to_message($message);
is( $slack_message->content, 'well, then, @foo', '_slack_message_to_message has user normalized');

$message->{'text'} = 'is <i>obviously</i> heading';
$slack_message = $slack->_slack_message_to_message($message);
is( $slack_message->content, 'is obviously heading', '_slack_message_to_message has HTML filtered');

$message->{'text'} = 'to <http://www.google.com>';
$slack_message = $slack->_slack_message_to_message($message);
is( $slack_message->content, 'to http://www.google.com', '_slack_message_to_message has URL normalized');

$message->{'text'} = 'well, then, <@foo> is <i>obviously</i> heading to <http://www.google.com>';
$slack_message = $slack->_slack_message_to_message($message);
is( $slack_message->content, 'well, then, @foo is obviously heading to http://www.google.com', '_slack_message_to_message has all in place');

done_testing();

1;
