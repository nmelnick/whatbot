###########################################################################
# whatbot/Timer.pm
###########################################################################
#
# Timer functionality for whatbot
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Timer;
use Moose;

BEGIN { extends 'whatbot::Component' };

# time_queue is an array. each item is of the form:
#  [ int time, coderef sub, ...  ]
#
# "..." can be any number of args to be sent to the sub when it is called at time.
has 'time_queue' => ( is => 'rw', isa => 'ArrayRef', default => sub { return [] } );

has 'next_time'  => ( is => 'rw', isa => 'Int', default => 0 );

sub enqueue {
	my ( $self, $time, $sub, @args ) = @_;
	
	if ($time < 86400) {
		$time += time;
	}
	
	my $new_item = [$time, $sub, @args];
	my $queue = $self->time_queue;
	
	# ensure queue is always in ascending order, by inserting
	# into the proper location
	
	my $index = 0;
	if (@$queue) {
		my $index = 0;
		
		# look for the first time which is above new_item's
		while ($index <= $#{$queue}) {
			my $index_time = $queue->[$index]->[0];
			
			if ($index_time > $time) {
				# our new item should go before this one
				my $insert_at = $index - 1;
				
				splice @$queue, $insert_at, 0, $new_item;
				
				if ($insert_at == 0) {
					$self->next_time($time);
				}
				
				return;
			}
			$index++;
		}
		
		# none were above new_item's time
		push @$queue, $new_item;
	} else {
		# this is the only one
		
		push @$queue, $new_item;
		$self->next_time($time);
	}
}

sub remove {
	my ( $self, $time, $sub, @args ) = @_;
	
	# remove the first perfect match. I doubt this will be called much, 
	# but here it is anyway
	my $match_item = [$time, $sub, @args];
	my $queue = $self->time_queue;
	
	if (@$queue) {
		my $index = 0;
		
		while ($index <= $match_item) {
			my $item = $queue->[$index];
			
			if (@$item == @$match_item) {
				my $i;
				my $ok = 1;
				for ($i = 0; $i <= $#$item; $i++) {
					if ($item->[$i] != $match_item->[$i]) {
						$ok = 0;
					}
				}
				if ($ok) {
					# remove it!
					splice @$queue, $index, 1;
					
					# if we took it off the front, adjust next_time
					if ($index == 0) {
						if (@$queue) {
							# next time is the time of the thing at the front
							$self->next_time($queue->[0]->[0]);
						} else {
							$self->next_time(0);
						}
					}
					return 1;
				}
			}
		}
	}
	
	return 0;
}

sub tick {
	my ( $self ) = @_;
	
	my $next = $self->next_time;
	return unless $next;
	
	my $now  = time;
	return if ($now <= $next);
	
	my $queue = $self->time_queue;
	
	if (@$queue) {
		my ($when, $sub, @args) = @{$queue->[0]};
		
		if ($when > $now) {
			# uh oh...
			$self->log->error("last_time in timer was not the same as the first item in the queue...");
		} else {
			&$sub(@args);
			shift @$queue;
			
			if (@$queue) {
				# next time is the time of the thing at the front
				$self->next_time($queue->[0]->[0]);
			} else {
				$self->next_time(0);
			}
		}
	}
}

1;


=pod

=head1 NAME

whatbot::Timer - Timer functionality for whatbot.

=head1 SYNOPSIS

 sub something_awesome : GlobalRegEx('do it later') {
     my ( $self, $message ) = @_;
     
     my $medium = $message->origin;
     $self->timer->enqueue(10, \&done_later, $self, $medium, "it");
     return "ok";
 }

 sub done_later {
     my ( $self, $medium, $what ) = @_;
     
     my $response = new whatbot::Message (
         from    => $medium->me,
         to      => "",
         content => "I did $what"
     );
     
     $medium->send_message($response);
 }

=head1 DESCRIPTION

whatbot::Timer - Timer functionality for whatbot.

=head1 PUBLIC METHODS

=over 4

=item enqueue($when, $sub, [@args ...])

The only way to really interact with the timer. C<$when> is in seconds -- 
either seconds since Jan 1 1970, or, if less than 86400, seconds from now. 
C<$sub> is a reference to any code, and C<@args>, if provided, are passed 
directly to that subroutine at call-time.

=item tick()

Called every event loop, from the main whatbot class. Runs all code scheduled
for this second. If called multiple times per second, only runs once.

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Timer

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
