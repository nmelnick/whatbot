###########################################################################
# whatbot/Store.pm
###########################################################################
# Base class for whatbot Storage
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Store;
use Moose;
extends 'whatbot::Component';
use Digest::SHA1 qw(sha1_hex);

has 'handle' => (
	is	=> 'rw',
	isa	=> 'Any'
);

sub connect {
	my ($self) = @_;
}

sub store {
	my ($self, $table, $assignRef) = @_;
}

sub retrieve {
	my ($self, $table, $columnRef, $queryRef, $numberItems) = @_;
}

sub delete {
	my ($self, $table, $queryRef) = @_;
}

sub update {
	my ($self, $table, $assignRef, $queryRef) = @_;
}

sub factoid {
	my ($self, $subject, $is, $from, $plural) = @_;
	
	return undef if (!$subject);
	my $original = $subject;
	$subject = lc($subject);
	
	# Get existing factoid info, if available
	my ($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id is_or is_plural silent/], { subject => $subject }) };
	return undef if (!defined($factoid) and !$is);
	
	# Assign fact info if defined
	if ($is) {
		
		# Nuke all factoids if user says no
		if ($subject =~ /no, /i) {
			$subject =~ s/no, //i;
			$self->forget($subject);
		}
		
		unless (defined $factoid) {
			# Check if ignore
			return undef if ($self->ignore($subject));
			
			# Check if plural
			my $isPlural = $plural;
			# if (length($subject) > 2 and $subject =~ /s$/ and $subject !~ /'s$/) {
			# 	if ($subject =~ /(s|z|x|sh|ch|[^aeiou]y)es$/) {
			# 		$isPlural = 1;
			# 	} elsif ($original =~ /^[A-Z][a-z]+$/) {
			# 		$isPlural = 0;
			# 	}
			# }
			
			$self->store("factoid", {
				is_or		=> 0,
				is_plural	=> $isPlural,
				created		=> time,
				updated		=> time,
				subject		=> $subject
			});
			($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id is_or is_plural silent/], { subject => $subject }) };
		}
		
		# Remove also, because we don't care
		my $also = 0;
		if ($is =~ /^also/) {
			$also = 1;
			$is =~ s/^also //;
		}
		
		# Check for or
		if ($is =~ /^ *\|\| ?/) {
			$is =~ s/^ *\|\| ?//;
			$self->update("factoid", { is_or => 1 }, { factoid_id => $factoid->{factoid_id} });
			($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id is_or is_plural silent/], { subject => $subject }) };
		}
		
		# Nuke <reply> if not or and more than one fact
		if ($is =~ /^<reply>/) {
			my ($factoidCount) = @{ $self->retrieve("factoid_description", [ "COUNT(*) AS count" ], { factoid_id => $factoid->{factoid_id}}) };
			unless ($factoidCount->{count} == 0 or (defined $factoid->{is_or} and $factoid->{is_or} == 1)) {
				return undef;
			}
		}
		
		# Nuke response if we already have a reply
		my ($firstFact) = @{ $self->retrieve(
			"factoid_description",
			[qw/description/],
			{ factoid_id => $factoid->{factoid_id} },
			1
		) };
		if (defined $firstFact and $firstFact->{description} =~ /^<reply>/) {
			return undef;
		}	
			
		# Check if exists
		if (defined $factoid
			and my ($desc) = @{ $self->retrieve("factoid_description", [qw/factoid_id/], { factoid_id => $factoid->{factoid_id}, hash => sha1_hex($is) }) }) {
			return undef;
		}
		
		my $result = $self->store("factoid_description", {
			factoid_id	=> $factoid->{factoid_id},
			description	=> $is,
			hash		=> sha1_hex($is),
			user		=> $from,
			updated		=> time
		});
	}
	
	# Retrieve factoid description
	my @facts = @{ $self->retrieve(
		"factoid_description",
		[qw/description/],
		{ factoid_id => $factoid->{factoid_id} }
	) };
	
	# If facts are given, return hashref of factoid data and facts
	if (scalar(@facts) > 0) {
		for (my $i = 0; $i < scalar(@facts); $i++) {
			$facts[$i] = $facts[$i]->{description};
		}
		return {
			factoid	=> $factoid,
			facts	=> \@facts
		};
	}
	
	return undef;
}

sub forget {
	my ($self, $subject) = @_;
	
	return undef if (!$subject);
	$subject = lc($subject);
	
	my ($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id/], { subject => $subject }) };
	return undef unless (defined $factoid);
	
	$self->delete("factoid_description", { factoid_id => $factoid->{factoid_id} });
	$self->delete("factoid", { factoid_id => $factoid->{factoid_id} });
	
	return 1;
}

sub ignore {
	my ($self, $subject, $store) = @_;
	
	return undef if (!$subject);
	$subject = lc($subject);
	
	my ($ignore) = @{ $self->retrieve("factoid_ignore", [qw/subject/], { subject => $subject }) };
	
	if ($store and !defined $ignore) {
		$self->store("factoid_ignore", { subject => $subject });
		($ignore) = @{ $self->retrieve("factoid_ignore", [qw/subject/], { subject => $subject }) };
	}
	
	return $ignore;
}

sub seen {
	my ($self, $user, $message) = @_;
	
	return undef if (!$user);
	$user = lc($user);
	
	my ($itemRef) = @{$self->retrieve("seen", [qw/user timestamp message/], { user => $user })};
	if (defined $message) {
		$self->delete("seen", { user => $user });
		$self->store("seen", { user => $user, message => $message, timestamp => time });
		($itemRef) = @{$self->retrieve("seen", [qw/user timestamp message/], { user => $user })};
	}
	
	return $itemRef;
}

sub silentFactoid {
	my ($self, $subject, $store) = @_;
	
	return undef if (!$subject);
	$subject = lc($subject);
	
	my ($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id silent/], { subject => $subject }) };
	
	if ($store and defined $factoid and $factoid->{factoid_id} > 0) {
		if ($factoid->{silent} == 1) {
			$self->update("factoid", { silent => 0 }, { factoid_id => $factoid->{factoid_id} });
		} else {
			$self->update("factoid", { silent => 1 }, { factoid_id => $factoid->{factoid_id} });
		}
		($factoid) = @{ $self->retrieve("factoid", [qw/factoid_id silent/], { subject => $subject }) };
	}
	
	return (defined $factoid ? $factoid->{silent} : undef);
}

sub karma {
	my ($self, $subject, $extended) = @_;
	
	if ($extended) {
		my %return;
		my ($incRef) = @{$self->retrieve("karma", ["COUNT(amount) AS inc"], { subject => $subject, amount => 1 })};
		$return{Increments} = $incRef->{inc};
		my ($decRef) = @{$self->retrieve("karma", ["COUNT(amount) AS dec"], { subject => $subject, amount => -1 })};
		$return{Decrements} = $decRef->{dec};
		my ($lastRef) = @{$self->retrieve("karma", [qw/amount user/], { subject => $subject }, "karma_id DESC", 1)};
		$return{Last} = [$lastRef->{user}, $lastRef->{amount}];
		return \%return;
	} else {
		my ($karmaRef) = @{$self->retrieve("karma", ["SUM(amount) AS karma"], { subject => $subject })};
		return $karmaRef->{karma};
	}
}

sub karmaIncrement {
	my ($self, $subject, $from) = @_;
	
	return undef if (!$subject or $subject eq '' or $subject =~ /[\-\(\)\[\]\$]/);
	$subject = lc($subject);
	
	$self->store("karma", {
		subject	=> $subject,
		user	=> $from,
		amount	=> 1
	});
}

sub karmaDecrement {
	my ($self, $subject, $from) = @_;
	
	return undef if (!$subject or $subject eq '' or $subject =~ /[\-\(\)\[\]\$]/);
	$subject = lc($subject);
	
	$self->store("karma", {
		subject	=> $subject,
		user	=> $from,
		amount	=> -1
	});
}

1;