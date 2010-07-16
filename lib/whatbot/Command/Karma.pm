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

    my $karmas = $self->model('karma')->search({
        'user' => $who
    });

    if (!$karmas or !@$karmas) {
        return "$nick: I don't know what $who ${verb}s.";
    }

    my %karma;
    while (@$karmas) {
        $_ = shift(@$karmas);
        $karma{ $_->subject } += $_->amount;
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
		my $karma_info = $self->model('karma')->get_extended( $phrase );
		if (
		    defined $karma_info
		    and ( $karma_info->{'Increments'} != 0 or $karma_info->{'Decrements'} != 0 )
		) {
			my $rocks = sprintf( "%0.1f", 100 * ($karma_info->{'Increments'} / ($karma_info->{'Increments'} + $karma_info->{'Decrements'})) );
			my $sucks = sprintf( "%0.1f", 100 * ($karma_info->{'Decrements'} / ($karma_info->{'Increments'} + $karma_info->{'Decrements'})) );
			return 
				"$phrase has had " . $karma_info->{'Increments'} . " increments and " . $karma_info->{'Decrements'} . " decrements, for a total of " . ($karma_info->{'Increments'} - $karma_info->{'Decrements'}) . 
				". $phrase " . ($rocks > $sucks ? "$rocks% rocks" : "$sucks% sucks") . 
				". Last change was by " . $karma_info->{'Last'}->[0] . ", who gave it a " . ($karma_info->{'Last'}->[1] == 1 ? '++' : '--') . ".";
		} else {
			return "$phrase has no karma";
		}
	}
}

sub parse_message : GlobalRegEx('[\+\-]{2}') {
	my ( $self, $message ) = @_;

    if ( $message->content =~ /\((.*?)\)([\+\-][\+\-])/ ) {
		# more than one word
		my $phrase = $1;
		my $op = $2;
		return $self->parse_operator( $phrase, $op, $message->from );
		
	} elsif  ( $message->content =~ /([^ ]+)([\+\-][\+\-])/ ) {
		# one word
		my $word = $1;
		my $op = $2;
		return $self->parse_operator( $word, $op, $message->from );

	}
	
	return undef;
}

sub karma : CommandRegEx('(.*)') {
    my ( $self, $message, $captures ) = @_;
    
    if ($captures) {
		my $phrase = $captures->[0];
		return if ( $phrase =~ /^info/ );   # Hack to pass through if requesting info
		my $karma = $self->model('karma')->get($phrase);
		if ( $karma and $karma != 0 ) {
			return "$phrase has a karma of $karma";
		} else {
			return "$phrase has no karma";
		}
    }
}

sub parse_operator {
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
	
	return $self->model('karma')->increment( $subject, $from );
}

sub decrement {
	my ( $self, $subject, $from ) = @_;
	
	return $self->model('karma')->decrement( $subject, $from );
}

1;

