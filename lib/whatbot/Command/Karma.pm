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
BEGIN { extends 'whatbot::Command'; }

my $LIKE_NUM = 10;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Core');
	$self->require_direct(0);
}

sub what_does : GlobalRegEx('(what|who) does (\w+) (like|hate)') {
    my ( $self, $message, $captures ) = @_;
    
    # summarize someone's like/hates
    my $who = $captures->[1];
    my $verb = $captures->[2];
    my $nick = $message->from;

    my $karmas = $self->store->retrieve('karma', [ 'subject', 'amount' ], { 'user' => $who });

    if (!$karmas or !@$karmas) {
        return "$nick: I don't know what $who ${verb}s.";
    }

    my %karma;
    while (@$karmas) {
        $_ = shift(@$karmas);
        $karma{ $_->{'subject'} } += $_->{'amount'};
    }

    # find top (or bottom) 5
    my @sorted;
    if ($verb eq 'like') { 
        @sorted = sort { $karma{$b} <=> $karma{$a} } keys %karma;
    }
    else {
        @sorted = sort { $karma{$a} <=> $karma{$b} } keys %karma;
    }
    @sorted = @sorted[ 0 .. (@sorted < $LIKE_NUM ? $#sorted : $LIKE_NUM - 1) ];

    my @results;
    foreach (@sorted) {
        last if ( $verb eq 'like' ? $karma{$_} < 0 : $karma{$_} > 0 );
        push( @results, $_ . '(' . $karma{$_} . ')' );
    }
    undef %karma;

    return "$who ${verb}s: " . join ( ', ', @results );
}

sub info : Command {
    my ( $self, $message, $captures ) = @_;
    
    if ($captures) {
		my $phrase = join( ' ', @$captures );
		my $karmaInfo = $self->store->karma( $phrase, 1 );
		if (
		    defined $karmaInfo
		    and ( $karmaInfo->{'Increments'} != 0 or $karmaInfo->{'Decrements'} != 0 )
		) {
			my $rocks = sprintf( "%0.1f", 100 * ($karmaInfo->{'Increments'} / ($karmaInfo->{'Increments'} + $karmaInfo->{'Decrements'})) );
			my $sucks = sprintf( "%0.1f", 100 * ($karmaInfo->{'Decrements'} / ($karmaInfo->{'Increments'} + $karmaInfo->{'Decrements'})) );
			return 
				"$phrase has had " . $karmaInfo->{'Increments'} . " increments and " . $karmaInfo->{'Decrements'} . " decrements, for a total of " . ($karmaInfo->{'Increments'} - $karmaInfo->{'Decrements'}) . 
				". $phrase " . ($rocks > $sucks ? "$rocks% rocks" : "$sucks% sucks") . 
				". Last change was by " . $karmaInfo->{'Last'}->[0] . ", who gave it a " . ($karmaInfo->{'Last'}->[1] == 1 ? '++' : '--') . ".";
		}
	}
}

sub parse_message : GlobalRegEx('[\+\-]{2}') {
	my ( $self, $message ) = @_;

    if ( $message->content =~ /\((.*?)\)([\+\-][\+\-])/ ) {
		# more than one word
		my $phrase = $1;
		my $op = $2;
		return $self->parseOperator( $phrase, $op, $message->from );
		
	} elsif  ( $message->content =~ /([^ ]+)([\+\-][\+\-])/ ) {
		# one word
		my $word = $1;
		my $op = $2;
		return $self->parseOperator( $word, $op, $message->from );

	}
	
	return undef;
}

sub karma : CommandRegEx('(.*)') {
    my ( $self, $message, $captures ) = @_;
    
    if ($captures) {
		my $phrase = $captures->[0];
		return if ( $phrase =~ /^info/ );   # Hack to pass through if requesting info
		my $karma = $self->store->karma($phrase);
		if (defined $karma and $karma != 0) {
			return "$phrase has a karma of $karma";
		} else {
			return "$phrase has no karma";
		}
    }
}

sub parseOperator {
	my ( $self, $subject, $operator, $from ) = @_;
	
	$subject =~ s/\++$//;
	$subject =~ s/\-+$//;
	$subject = lc($subject);
	return undef if ( $subject eq lc($from) );
	
	if ( $operator eq '++' ) {
		$self->increment( $subject, $from );
	} elsif ( $operator eq '+-' or $operator eq '-+' ) {
	} else {
		$self->decrement( $subject, $from );
	}
	
	return;
}

sub increment {
	my ( $self, $subject, $from ) = @_;
	
	return $self->store->karmaIncrement($subject, $from);
}

sub decrement {
	my ( $self, $subject, $from ) = @_;
	
	return $self->store->karmaDecrement($subject, $from);
}

1;
