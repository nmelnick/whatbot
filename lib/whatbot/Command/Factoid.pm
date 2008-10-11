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

has 'stfu' => ( is => 'rw', isa => 'HashRef', default => sub { { 'subject' => '', 'time' => '' }; } );

sub register {
	my ($self) = @_;
	
	$self->command_priority('Core');
	$self->require_direct(0);
}

sub what_is : GlobalRegEx('^(wtf|what|who) (is|are) (.*)') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	return $self->retrieve( $captures->[2], $message, 1 );
}

sub assign : GlobalRegEx('^(.*) (is|are) (.*)') {
    my ( $self, $message, $captures ) = @_;
    
	my $is_plural = ( $captures->[1] =~ /are/i ? 1 : 0 );
	$captures->[2] =~ s/[\. ]$//g;	        # remove trailing punctuation
	unless ( $message->is_direct ) {
		$captures->[2] =~ s/\[\.,] .*$//g;  # if capturing flyby, only grab one sentence
	}
	if ( $message->is_direct and lc( $captures->[0] ) eq 'you' ) {
		$captures->[0] = $message->me;
	}
	foreach my $factoid ( split( / or /, $captures->[2] ) ) {
		$self->store->factoid( $captures->[0], $factoid, $message->from, $is_plural );
	}
	return;
}

sub never_remember : GlobalRegEx('^never remember (.*)') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	# Delete forever
	$self->store->forget( $captures->[0] );
	$self->store->ignore( $captures->[0], 1 );
	return 'I will permanently forget "' . $captures->[0] . '", ' . $message->from . '.';
}

sub forget : GlobalRegEx('^forget (.*)') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	# Delete
	my $result = $self->store->forget( $captures->[0] );
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
		
		my $factoid_facts = $self->store->retrieve('factoid_description', [qw/factoid_id description user/], { 'description' => 'LIKE %' . $look_for . '%' });
		my $factoid_desc = $factoid_facts->[int(rand(scalar(@{$factoid_facts}))) - 1];
		($factoid) = @{$self->store->retrieve('factoid', [qw/subject is_plural/], { 'factoid_id' => $factoid_desc->{'factoid_id'} })};
		
		# Who said
		$self->{'last_random_fact_who_said'} = $factoid_desc->{'user'};
		
		# Override retrieve
		my $subject = $factoid->{'subject'};
		my $description = $factoid_desc->{'description'};
		if ( $description =~ /^<reply>/ ) {
			$description =~ s/^<reply> +//;
			return $description;
		} else {
			$subject = 'you' if ( lc($subject) eq lc($message->from) );
			$subject = $message->from . ', ' . $subject if ( $message->is_direct );
			return $subject . ' ' . ( $factoid->{'is_plural'} ? 'are' : 'is' ) . ' ' . $description;
		}
		return;
		
	} else {
		my ($count) = @{$self->store->retrieve('factoid', ['COUNT(*) as Count'])};
		$count = $count->{'Count'};
		my $factoid_id = int(rand($count));
		$factoid_id = 1 unless ($factoid_id);
		($factoid) = @{$self->store->retrieve('factoid', [qw/subject/], { 'factoid_id' => $factoid_id })};

		# Who said
		my $users = $self->store->retrieve('factoid_description', [qw/user/], { 'factoid_id' => $factoid_id });
		my $response;
		foreach my $user (@{$users}) {
			$response .= ', ' if ( defined $response );
			$response .= $user->{'user'};
		}
		$self->{'last_random_fact_who_said'} = $response;
		return $self->retrieve( $factoid->{'subject'}, $message );
		
	}

}

sub who_said : GlobalRegEx('^who said that') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	if ( defined $self->{'last_random_fact_who_said'} ) {
		if ( $message->from eq $self->{'last_random_fact_who_said'} ) {
		    return $message->from . ': it was YOU!';
		} else {
		    return $message->from . ': ' . $self->{'last_random_fact_who_said'};
	    }
	}
	
	return;
}

sub stfu : GlobalRegEx('^(shut up|stfu) about (.*)') : StopAfter {
    my ( $self, $message, $captures ) = @_;
    
	# STFU about
	if ( $self->stfu->{'subject'} eq $captures->[1] and (time - $self->stfu->{'time'}) < 45 ) {
		return undef;
		
	} elsif ( defined $self->stfu ) {
		$self->stfu({
		    'subject' => '',
		    'time'    => ''
		});
	}
	
	my $silent = $self->store->silent_factoid( $captures->[1], 1 );
	if ( defined $silent ) {
		$self->stfu({
			'subject' => $captures->[1],
			'time'    => time
		});
		
		if ($silent == 1) {
			return "I will shut up about '" . $captures->[1] . "', " . $message->from . ".";
		} else {
			return "I will keep talking about '" . $captures->[1] . "', " . $message->from . ".";
		}
	} else {
		return "I don't have any facts for '" . $captures->[1] . "', " . $message->from . ".";
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
	my $factoid = $self->store->factoid($subject);
	if (
	    defined $factoid
	    and (
	        !( $factoid->{'factoid'}->{'silent'} and $factoid->{'factoid'}->{'silent'} == 1 )
	        or $direct
	    )
	) {
		my @facts;
		if ( defined $factoid->{'factoid'}->{'is_or'} and $factoid->{'factoid'}->{'is_or'} == 1 ) {
			my $fact_count = scalar( @{$factoid->{'facts'}} );
			push( @facts, $factoid->{'facts'}->[int(rand($fact_count))] );
		} else {
			@facts = @{$factoid->{'facts'}};
		}
		
		if ( scalar(@facts) == 1 and $facts[0] =~ /^<reply>/ ) {
			$facts[0] =~ s/^<reply> +//;
			return $facts[0];
		} else {
			if ( lc($subject) eq lc($message->from) ) {
			    $subject = 'you';
			    $factoid->{'factoid'}->{'is_plural'} = 1;
			}
			$subject = $message->from . ', ' . $subject if ( $message->is_direct );
			my $factoidData = join( ' or ', @facts );
			if ( !$everything and length($factoidData) > 400 ) {
				$factoidData = 'summarized as ';
				my $start = 0;
				my $bigTries = 0;
				my $totalTries = 0;
				my %usedFacts;
				while ( length($factoidData) < 380 and $bigTries < 5 and $totalTries < 10 ) {
					my $factNum = int(rand(scalar(@facts)));
					if ( defined $usedFacts{$factNum} ) {
						$totalTries++;
					} else {
						$usedFacts{$factNum} = 1;
						if ( length($factoidData . $facts[$factNum]) > 410 ) {
							$bigTries++;
							next;
						}
						$factoidData .= ' or ' unless ( $start == 0 );
						$factoidData .= $facts[$factNum];
						$start++;
					}
				}
			}
			return $subject . ' ' . ($factoid->{'factoid'}->{'is_plural'} ? 'are' : 'is') . ' ' . $factoidData;
		}
		
	} elsif ( $direct and $message->is_direct ) {
		return "I have no idea what '" . $subject . "' could be, " . $message->from . ".";
		
	}
	
	return;
}

1;
