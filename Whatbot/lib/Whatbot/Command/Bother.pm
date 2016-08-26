###########################################################################
# Whatbot/Command/Bother.pm
###########################################################################
# Bug someone
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;
use Whatbot::Command;

class Whatbot::Command::Bother extends Whatbot::Command {
	has 'timers' => ( is => 'ro', default => sub { {} } );

	method register() {
		$self->command_priority('Extension');
		$self->require_direct(0);
		$self->init_timers();
	}

	method bother( $message?, $captures? ) : GlobalRegEx('^(bother|bug) ([\w, \@]+) about (.*?) every (.*)$') {
		my @users = map { s/^\@//; $_; } ( split( /,\s+/, $captures->[1] ) );
		my $about = $captures->[2];
		my $every = $captures->[3];
		my $word = $captures->[0];
		if ( $every !~ /^\d+$/ ) {
			my ( $amount, $unit ) = split( /\s+/, $every );
			if ( $unit =~ /^minutes?/ ) {
				$amount *= 60;
			} elsif ( $unit =~ /^hours?/ ) {
				$amount = $amount * 60 * 60;
			} elsif ( $unit =~ /^days?/ ) {
				$amount = $amount * 60 * 60 * 24;
			} elsif ( $unit =~ /^weeks?/ ) {
				$amount = $amount * 60 * 60 * 24 * 7;
			} elsif ( $unit =~ /^months?/ ) {
				$amount = $amount * 60 * 60 * 24 * 30;
			} else {
				return 'I have no idea how to deal with the unit "' . $unit . '".';
			}
			$every = $amount;
		}

		foreach my $user (@users) {
			my $added = $self->model('Bother')->add( $user, $about, $every, $message->origin );
			$self->queue_timer($added);
		}
		return sprintf( 'I will %s %s about "%s" every %d seconds.', $word, join( ', ', @users ), $about, $every );
	}

	method stop( $message?, $captures? ) : GlobalRegEx('^stop b(ugg|other)ing me') {
		return $self->do_stop( $message->from );
	}

	method stop_user( $message?, $captures? ) : GlobalRegEx('^stop b(ugg|other)ing (\w+)') {
		my $user = $captures->[1];
		return if ( $user eq 'me' );
		return $self->do_stop($user);
	}

	method do_stop($user) {
		my $count = $self->model('Bother')->acknowledge_all_for($user);
		if (@$count) {
			foreach my $bother (@$count) {
				$self->dequeue_timer($bother);
			}
			return 'I will stop bugging ' . $user . '.';
		}
		return 'I am not bugging ' . $user . ' about anything.';
	}

	method help( $message?, $captures? ) : Command {
	    return [
	        'Bug will bug one or more users about any topic until they stop it. ',
	        ' * "bug this_user about heading out tomorrow every 1 hour" - every hour, send "Hey, this_user. I am bugging you about heading out tomorrow."',
	        ' * "stop bugging me" - acknowledge that you have been bothered, and stop',
	        ' * "stop bugging this_user" - acknowledge on another user\'s behalf',
	    ];
	}

	method notify_bother( $user, $about, $origin ) {
		my $bug = 'Hey, ' . $user . '. I am bugging you about ' . $about . '.';
		my $channel = $origin;
		$channel =~ s/^.*?\://;
		$self->send_message(
			$origin,
			Whatbot::Message->new({
				'from'      => 'me',
				'to'        => 'public',
				'content'   => $bug,
				'invisible' => 1,
			}),
		);
		return;
	}

	method init_timers() {
		my $bothers = $self->model('Bother')->get_active();
		foreach my $bother (@$bothers) {
			$self->queue_timer($bother);
		}
	}

	method queue_timer($record) {
		my $timer = AnyEvent->timer(
			'after'    => $record->every,
			'interval' => $record->every,
			'cb'       => sub {
				$self->notify_bother( $record->user, $record->about, $record->origin );
			},
   		);
   		my $key = join( '-', $record->user, $record->about );
   		$self->timers->{$key} = $timer;
	}

	method dequeue_timer($record) {
   		my $key = join( '-', $record->user, $record->about );
   		undef $self->timers->{$key};
	}
}

1;
