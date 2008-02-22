###########################################################################
# whatbot/Command/Karma.pm
###########################################################################
# Similar to infobot's karma system, this is part of the core bot
# functionality
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Karma;
use Moose;
extends 'whatbot::Command';

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Core");
	$self->listenFor([
		qr/\+\+/,
		qr/\-\-/,
		qr/karma/i,
                qr/what does (\w+) (like|hate)\??$/io,
	]);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;

        if ($messageRef->content =~ /what does (\w+) (like|hate)/) {
                # summarize someone's like/hates
                my $who = $1;
                my $verb = $2;
                my $find = ($verb eq "like" ? 1 : -1);
                my $nick = $messageRef->from;

                my $karmas = $self->store->retrieve("karma", [ "subject", "amount" ], { user => $who, amount => $find });

                if (!$karmas || !@$karmas) {
                    return "$nick: I don't know what $who ${verb}s.";
                }

                my %karma;
                # use shift to hopefully minimize memory usage
                while (@$karmas) {
                    $_ = shift @$karmas;
                    $karma{$_->{subject}} += $_->{amount};
                }
                $self->log->write("$who -- $_ -- $karma{$_}") foreach keys %karma;

                # find top (or bottom) 5
                my @sorted;
                if ($verb eq "like") { 
                    @sorted = sort { $karma{$b} <=> $karma{$a} } keys %karma;
                }
                else {
                    @sorted = sort { $karma{$a} <=> $karma{$b} } keys %karma;
                }
                @sorted = @sorted[ 0 .. ($#sorted < 4 ? $#sorted : 4) ];

                my @results;
                push @results, "$_ (" . $karma{$_} . ")" foreach @sorted;
                undef %karma;

                return "$who ${verb}s: " . join (', ', @results);
	} elsif ($messageRef->content =~ /\((.*?)\)([\+\-][\+\-])/) {
		# more than one word
		my $phrase = $1;
		my $op = $2;
		return $self->parseOperator($phrase, $op, $messageRef->from);
		
	} elsif ($messageRef->content =~ /([^ ]+)([\+\-][\+\-])/) {
		# one word
		my $word = $1;
		my $op = $2;
		return $self->parseOperator($word, $op, $messageRef->from);
		
	} elsif ($messageRef->content =~ /^karma info (.*)/i) {
		# Get karma info
		my $phrase = $1;
		my $karmaInfo = $self->store->karma($phrase, 1);
		if (defined $karmaInfo and ($karmaInfo->{Increments} != 0 or $karmaInfo->{Decrements} != 0)) {
			my $rocks = sprintf("%0.1f", 100 * ($karmaInfo->{Increments} / ($karmaInfo->{Increments} + $karmaInfo->{Decrements})));
			my $sucks = sprintf("%0.1f", 100 * ($karmaInfo->{Decrements} / ($karmaInfo->{Increments} + $karmaInfo->{Decrements})));
			return 
				"$phrase has had " . $karmaInfo->{Increments} . " increments and " . $karmaInfo->{Decrements} . " decrements, for a total of " . ($karmaInfo->{Increments} - $karmaInfo->{Decrements}) . 
				". $phrase " . ($rocks > $sucks ? "$rocks% rocks" : "$sucks% sucks") . 
				". Last change was by " . $karmaInfo->{Last}->[0] . ", who gave it a " . ($karmaInfo->{Last}->[1] == 1 ? '++' : '--') . ".";
		}
		
	} elsif ($messageRef->content =~ /^karma (.*)/i) {
		# Get karma
		my $phrase = $1;
		my $karma = $self->store->karma($phrase);
		if (defined $karma and $karma != 0) {
			return "$phrase has a karma of $karma";
		} else {
			return "$phrase has no karma";
		}
	}
	
	return undef;
}

sub parseOperator {
	my ($self, $subject, $operator, $from) = @_;
	
	$subject =~ s/\++$//;
	$subject =~ s/\-+$//;
	$subject = lc($subject);
	return undef if ($subject eq $from);
	
	if ($operator eq '++') {
		$self->increment($subject, $from);
		return "lastRun";
	} elsif ($operator eq '+-' or $operator eq '-+') {
	} else {
		$self->decrement($subject, $from);
		return "lastRun";
	}
}

sub increment {
	my ($self, $subject, $from) = @_;
	
	return $self->store->karmaIncrement($subject, $from);
}

sub decrement {
	my ($self, $subject, $from) = @_;
	
	return $self->store->karmaDecrement($subject, $from);
}

1;
