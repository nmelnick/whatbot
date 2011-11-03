###########################################################################
# whatbot/Command/Factoid.pm
###########################################################################
# Similar to infobot's assignment system, this is the core bot
# functionality
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Factoid;
use Moose;
BEGIN { extends 'whatbot::Command'; }

use DateTime;
use namespace::autoclean;

has 'stfu'     => ( is => 'rw', isa => 'HashRef', default => sub { { 'subject' => '', 'time' => '' }; } );
has 'who_said' => ( is => 'rw', isa => 'Str' );
has 'when_was' => ( is => 'rw', isa => 'Int' );

sub register {
	my ($self) = @_;
	
	$self->command_priority('Core');
	$self->require_direct(0);
}

sub what_is : GlobalRegEx('^(wtf|what|who) (is|are) (.*)') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	return $self->retrieve( $captures->[2], $message, 1 );
}

sub assign : GlobalRegEx('^(.*?) (is|are) (.*)') {
    my ( $self, $message, $captures ) = @_;
    
    my ( $subject, $assigner, $description ) = @$captures;
	my $is_plural = ( $assigner =~ /are/i ? 1 : 0 );
	$description =~ s/[\. ]$//g;	        # remove trailing punctuation
	unless ( $message->is_direct ) {
		$description =~ s/\[\.,] .*$//g;  # if capturing flyby, only grab one sentence
	}
	if ( $message->is_direct and lc($subject) eq 'you' ) {
		$subject = $message->me;
	}
	foreach my $factoid ( split( / or /, $description ) ) {
		$self->model('Factoid')->factoid( $subject, $factoid, $message->from, $is_plural );
	}
	return;
}

sub never_remember : GlobalRegEx('^never remember (.*)') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	# Delete forever
	$self->model('Factoid')->forget( $captures->[0] );
	$self->model('Factoid')->ignore( $captures->[0], 1 );
	return 'I will permanently forget "' . $captures->[0] . '", ' . $message->from . '.';
}

sub forget : GlobalRegEx('^forget (.*)') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	# Delete
	my $result = $self->model('Factoid')->forget( $captures->[0] );
	if ($result) {
		return 'I forgot "' . $captures->[0] . '", ' . $message->from . '.';
	}
	return;
}

sub random_fact : GlobalRegEx('^(random fact|jerk it)') : StopAfter {
    my ( $self, $message, $captures ) = @_;

	# Random fact
	my $factoid;
	if ( $message->content =~ m/random fact (for|about) (.*)/ and $2 ) {
		my $look_for = $2;
		$look_for =~ s/[\.\?\! ]$//;
		
		my $factoid_facts = $self->model('Factoid')->table_description->search({
			'description' => { 'LIKE' => '%' . $look_for . '%' }
		});
		if (@$factoid_facts) {
    		my $factoid_desc = $factoid_facts->[int(rand(scalar(@{$factoid_facts}))) - 1];
    		$factoid = $self->model('Factoid')->find( $factoid_desc->factoid_id );
		
    		# Who said/When was
    		$self->who_said( $factoid_desc->user );
    		$self->when_was( $factoid_desc->updated );
		
    		# Override retrieve
    		my $subject = $factoid->subject;
    		my $description = $factoid_desc->description;
    		if ( $description =~ /^<reply>/ ) {
    			$description =~ s/^<reply> +//;
    			return $description;
    		} else {
    			$subject = 'you' if ( lc($subject) eq lc( $message->from ) );
    			$subject = $message->from . ', ' . $subject if ( $message->is_direct );
    			return $subject . ' ' . ( $factoid->is_plural ? 'are' : 'is' ) . ' ' . $description;
    		}
    	} else {
    	    return 'Nothing found for "' . $look_for . '".';
    	}
		return;
		
	} else {
		my $count = $self->model('Factoid')->count();
		my $factoid_id = int(rand($count));
		$factoid_id = 1 unless ($factoid_id);
		$factoid = $self->model('Factoid')->find($factoid_id);

		# Who said
		my $users = [ map { $_->user } @{ $self->model('Factoid')->table_description->search({ 'factoid_id' => $factoid_id } ) } ];

		my $response;
		foreach my $user (@$users) {
			$response .= ', ' if ( $response );
			$response .= $user;
		}
		$self->who_said( $response or '' );
		$self->when_was( @$users > 1 ? 0 : $factoid->updated );
		return $self->retrieve( $factoid->subject, $message );
		
	}

}

sub who_said_that : GlobalRegEx('^(who said that)') : StopAfter {
    my ( $self, $message, $captures ) = @_;

	if ( $self->who_said ) {
		if ( $message->from eq $self->who_said ) {
		    return $message->from . ': it was YOU!';
		} else {
		    return $message->from . ': ' . $self->who_said;
	    }
	}
	
	return;
}

sub when_was_that : GlobalRegEx('^(when was that)') : StopAfter {
    my ( $self, $message, $captures ) = @_;

	if ( $self->when_was ) {
		my $dt = DateTime->from_epoch( epoch => $self->when_was );
		return 'Looks like it was on ' . $dt->ymd . ' at ' . $dt->hms . '.';
	}
	
	return 'No idea.';
}

sub shut_up : GlobalRegEx('^(shut up|stfu) about (.*)') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	# STFU about
	if ( $self->stfu->{'subject'} eq $captures->[1] and ( time - $self->stfu->{'time'} ) < 45 ) {
		return undef;
		
	} elsif ( defined $self->stfu ) {
		$self->stfu({
		    'subject' => '',
		    'time'    => ''
		});
	}
	
	my $silent = $self->model('factoid')->toggle_silence( $captures->[1] );
	if ( defined $silent ) {
		$self->stfu({
			'subject' => $captures->[1],
			'time'    => time
		});
		
		if ( $silent == 1 ) {
			return 'I will shut up about "' . $captures->[1] . '", ' . $message->from . '.';
		} else {
			return 'I will keep talking about "' . $captures->[1] . '", ' . $message->from . '.';
		}
	} else {
		return 'I do not have any facts for "' . $captures->[1] . '", ' . $message->from . '.';
	}
	
	return;
}

sub retrieve {
	my ( $self, $subject, $message, $direct ) = @_;

	my $everything = 0;	
	$subject =~ s/[\?\!\. ]*$//;
	if ( $subject =~ /^everything for/ ) {
		$subject =~ s/^everything for +//;
		$everything++;
	}
	my $factoid_package = $self->model('Factoid')->factoid($subject);
	if (
	    $factoid_package
	    and (
	        !( $factoid_package->{'factoid'}->silent and $factoid_package->{'factoid'}->silent == 1 )
	        or $direct
	    )
	) {
		my @facts;
		my $factoid = $factoid_package->{'factoid'};
		if ( defined $factoid->is_or and $factoid->is_or == 1 ) {
			my $fact_count = scalar( @{ $factoid_package->{'facts'} } );
			push( @facts, $factoid_package->{'facts'}->[int(rand($fact_count))] );
		} else {
			@facts = @{ $factoid_package->{'facts'} };
		}
		
		if ( scalar(@facts) == 1 ) {
			$self->who_said( $factoid_package->{'user'} ) if ( $factoid_package->{'user'} );
		}
		
		if ( scalar(@facts) == 1 and $facts[0] =~ /^<reply>/ ) {
			$facts[0] =~ s/^<reply> +//;
			return $facts[0];
		} else {
			if ( lc($subject) eq lc( $message->from ) ) {
			    $subject = 'you';
			    $factoid->is_plural(1);
			}
			$subject = $message->from . ', ' . $subject if ( $message->is_direct );
			my $factoid_data = join( ' or ', @facts );
			if ( !$everything and length($factoid_data) > 400 ) {
				$factoid_data = 'summarized as ';
				my $start = 0;
				my $big_tries = 0;
				my $total_tries = 0;
				my %used_facts;
				while ( length($factoid_data) < 380 and $big_tries < 5 and $total_tries < 10 ) {
					my $fact_num = int(rand(scalar(@facts)));
					if ( defined $used_facts{$fact_num} ) {
						$total_tries++;
					} else {
						$used_facts{$fact_num} = 1;
						if ( length($factoid_data . $facts[$fact_num]) > 410 ) {
							$big_tries++;
							next;
						}
						$factoid_data .= ' or ' unless ( $start == 0 );
						$factoid_data .= $facts[$fact_num];
						$start++;
					}
				}
			}
			return $subject . ' ' . ($factoid->is_plural ? 'are' : 'is') . ' ' . $factoid_data;
		}
		
	} elsif ( $direct and $message->is_direct ) {
		return "I have no idea what '" . $subject . "' could be, " . $message->from . ".";
		
	}
	
	return;
}

__PACKAGE__->meta->make_immutable;

1;
