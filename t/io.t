#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Whatbot::Test;
use Moops;

class Whatbot::IO::Test extends Whatbot::IO {
	has 'delivered' => ( is => 'rw' );

	method BUILD(...) {
		$self->me('test');
		$self->name('Test');
	}

	method deliver_message($message) {
		$self->delivered($message);
	}
}

my $test = Whatbot::Test->new();
$test->initialize_state();



use_ok( 'Whatbot::IO', 'Load Module' );

my $io = Whatbot::IO::Test->new({
	'my_config' => {},
});

is( $io->format_user('example-user'), 'example-user', 'format_user is no-op' );

my $message = $io->get_new_message({ 'content' => 'whee', 'from' => 'me', 'to' => 'public' });

is( $io->delivered, undef, 'delivered is false' );
ok( $io->send_message($message), 'send_message is called' );
is( ref( $io->delivered ), 'Whatbot::Message', 'delivered is true' );

$message->content('This is for {!user=someone}, not you');
$io->send_message($message);
is( $io->delivered->content, 'This is for someone, not you', 'format_user called correctly');

$message->content('This is for {!user=someone, not you');
eval {
	$io->send_message($message);
};
ok($@, 'send_message bails on unclosed user tag');
like( $@, qr/Unclosed user/, 'send_message throws message on unclosed user tag');

done_testing();

1;
