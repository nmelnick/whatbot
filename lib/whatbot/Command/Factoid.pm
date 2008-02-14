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
extends 'whatbot::Command';

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Core");
	$self->listenFor([
		qr/^(wtf|what) (is|are) (.*)/i,
		qr/^(.*) (is|are) (.*)/i,
		qr/^never remember (.*)/i,
		qr/^forget (.*)/i,
		qr/^(random fact|jerk it)/i,
		qr/^who said that/i,
		qr/^(shut up|stfu) about (.*)/,
		qr/(.*)/
	]);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef, $matchIndex, @matches) = @_;
	
	$messageRef->{matchIndex} = $matchIndex;
	
	if ($matchIndex == 0) {
		# Retrieve
		return $self->retrieve($matches[2], $messageRef);
		
	} elsif ($matchIndex == 1) {
		# Assign
		my $isPlural = ($matches[1] =~ /are/i ? 1 : 0);
		$matches[2] =~ s/[\. ]$//g;	# remove trailing punctuation
		unless ($messageRef->isDirect) {
			$matches[2] =~ s/\. .*$//g;		# if capturing flyby, only grab one sentence
		}
		if ($messageRef->isDirect and lc($matches[0]) eq 'you') {
			$matches[0] = $messageRef->me;
		}
		foreach my $factoid (split(/ or /, $matches[2])) {
			$self->store->factoid($matches[0], $factoid, $messageRef->from, $isPlural);
		}
		return "lastRun";
		
	} elsif ($matchIndex == 2) {
		# Delete forever
		$self->store->forget($matches[0]);
		$self->store->ignore($matches[0], 1);
		return "I will permanently forget '" . $matches[0] . "', " . $messageRef->from . ".";
		
	} elsif ($matchIndex == 3) {
		# Delete
		my $result = $self->store->forget($matches[0]);
		if ($result) {
			return "I forgot '" . $matches[0] . "', " . $messageRef->from . ".";
		}
		return "lastRun";
		
	} elsif ($matchIndex == 4) {
		# Random fact
		my $factoid;
		if ($messageRef->content =~ m/random fact (for|about) (.*)/ and $2) {
			my $lookFor = $2;
			$lookFor =~ s/[\.\?\! ]$//;
			my $factoidFacts = $self->store->retrieve("factoid_description", [qw/factoid_id description user/], { description => 'LIKE %' . $lookFor . '%' });
			my $factoidDesc = $factoidFacts->[int(rand(scalar(@{$factoidFacts}))) - 1];
			($factoid) = @{$self->store->retrieve("factoid", [qw/subject is_plural/], { factoid_id => $factoidDesc->{factoid_id} })};
			
			# Who said
			$self->{lastRandomFactWhoSaid} = $factoidDesc->{user};
			
			# Override retrieve
			my $subject = $factoid->{subject};
			my $description = $factoidDesc->{description};
			if ($description =~ /^<reply>/) {
				$description =~ s/^<reply> +//;
				return $description;
			} else {
				$subject = "you" if (lc($subject) eq lc($messageRef->from));
				$subject = $messageRef->from . ", $subject" if ($messageRef->isDirect);
				return $subject . " " . ($factoid->{is_plural} ? "are" : "is") . " " . $description;
			}
			return "lastRun";
			
		} else {
			my ($count) = @{$self->store->retrieve("factoid", ["COUNT(*) as Count"])};
			$count = $count->{Count};
			my $factoidId = int(rand($count));
			($factoid) = @{$self->store->retrieve("factoid", [qw/subject/], { factoid_id => $factoidId })};
			
			# Who said
			my $users = $self->store->retrieve("factoid_description", [qw/user/], { factoid_id => $factoidId });
			my $response;
			foreach my $user (@{$users}) {
				$response .= ", " if (defined $response);
				$response .= $user->{user};
			}
			$self->{lastRandomFactWhoSaid} = $response;
		}
		if (defined $factoid) {
			return $self->retrieve($factoid->{subject}, $messageRef);
		}
	
	} elsif ($matchIndex == 5) {
		# Who Said
		if (defined $self->{lastRandomFactWhoSaid}) {
			return $messageRef->from . ": " . $self->{lastRandomFactWhoSaid};
		}

	} elsif ($matchIndex == 6) {
		# STFU about
		my $silent = $self->store->silentFactoid($matches[1], 1);
		if (defined $silent) {
			if ($silent == 1) {
				return "I will shut up about '" . $matches[1] . "', " . $messageRef->from . ".";
			} else {
				return "I will keep talking about '" . $matches[1] . "', " . $messageRef->from . ".";
			}
		} else {
			return "I don't have any facts for '" . $matches[1] . "', " . $messageRef->from . ".";
		}
		

	} elsif ($matchIndex == 7) {
		# Retrieve
		return $self->retrieve($matches[0], $messageRef);
		
	}
	
	return undef;
}

sub retrieve {
	my ($self, $subject, $messageRef) = @_;
	
	$subject =~ s/[\?\!\. ]*$//;
	my $factoid = $self->store->factoid($subject);
	if (defined $factoid and ($factoid->{factoid}->{silent} != 1 or $messageRef->{matchIndex} == 0)) {
		my @facts;
		if (defined $factoid->{factoid}->{is_or} and $factoid->{factoid}->{is_or} == 1) {
			push(@facts, $factoid->{facts}->[rand @{$factoid->{facts}}]);
		} else {
			@facts = @{$factoid->{facts}};
		}
		
		if (scalar(@facts) == 1 and $facts[0] =~ /^<reply>/) {
			$facts[0] =~ s/^<reply> +//;
			return $facts[0];
		} else {
			$subject = "you" if (lc($subject) eq lc($messageRef->from));
			$subject = $messageRef->from . ", $subject" if ($messageRef->isDirect);
			return $subject . " " . ($factoid->{factoid}->{is_plural} ? "are" : "is") . " " . join(" or ", @facts);
		}
		
	} elsif ($messageRef->{matchIndex} == 0 and $messageRef->isDirect) {
		return "I have no idea what '" . $subject . "' could be, " . $messageRef->from . ".";
		
	}
	
	return "lastRun";
}

1;
