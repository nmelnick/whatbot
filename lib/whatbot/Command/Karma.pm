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
		qr/karma/i
	]);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	if ($messageRef->content =~ /\((.*?)\)([\+\-][\+\-])/) {
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
