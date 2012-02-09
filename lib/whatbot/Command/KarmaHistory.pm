###########################################################################
# whatbot/Command/KarmaHistory.pm
###########################################################################
# Using the karma history, determine what someone likes or doesn't like
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::KarmaHistory;
use Moose;
BEGIN { extends 'whatbot::Command' }
use namespace::autoclean;

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub fisher_yates_shuffle {
    my $array = shift;
    my $i;
    for ($i = @$array; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @$array[$i,$j] = @$array[$j,$i];
    }
}

sub random : GlobalRegEx('^(\w+) (like|hate)s what') {
	my ( $self, $message, $captures ) = @_;
	
	my ( $who, $verb ) = @$captures;
	
	my $nick = $message->from;
	my $op	 = ( $verb eq 'like' ? 1 : -1 );

	my $query = "
		SELECT subject, amount FROM karma WHERE 
		  amount = $op AND
		  user LIKE '$who' AND
		  subject NOT IN (SELECT subject FROM karma WHERE amount = $op and user NOT LIKE '$who')
	";
	my $sth = $self->model('karma')->database->handle->prepare($query);
    $sth->execute();
	my $karmas = $sth->fetchall_arrayref();

	if ( !$karmas or !@$karmas ) {
		return "$who doesn't $verb anything weird. that I know of.";
	}
	
	my $karma = $karmas->[rand($#$karmas)];

	return "$who ${verb}s $karma->[0] ($karma->[1]).";
}

sub controversy : GlobalRegEx('^[\. ]*?fightin(?:'|g)? words\??$') {
    my ( $self, $message, $captures ) = @_;

    my $limit = 10;

    my $sth = $self->model('karma')->database->handle->prepare("select subject, votes - votesum as score from (select subject, sum(amount) as votesum, sum(abs(amount)) as votes from karma group by subject) order by score desc limit $limit");
    $sth->execute();

    my $row;
    my @stuff;
    while ( $row = $sth->fetchrow_arrayref ) {
        my ( $subject, $score ) = @$row;
        push @stuff, "$subject ($score)";
    }
    return join(', ', @stuff);
}

sub superlative : GlobalRegEx('^[\. ]*?what(?: is|\'s)(?: the)? (best|worst)') {
	my ( $self, $message, $captures ) = @_;

	my $best = lc( $captures->[0] ) eq 'best';
	my $limit = 10;

	my $sort = ( $best ? "desc" : "asc" );
	my $sth = $self->database->handle->prepare("select subject, total from (select subject, sum(amount) as total from karma group by subject) order by total $sort limit $limit");
	$sth->execute();

	my $out = "The " . ($best ? "best" : "worst") . " of everything is: ";

	my $row;
	my @stuff;
	while ( $row = $sth->fetchrow_arrayref() ) {
		my ( $subject, $total ) = @$row;
		push @stuff, "$subject ($total)";
	}
	return join(', ', @stuff);
}

sub parse_message : GlobalRegEx('^[\. ]*?who (hates|likes|loves|doesn\'t like|plussed|minused) (.*)') {
	my ( $self, $message, $captures ) = @_;
	
	if ($captures) {
		my $what = lc( $captures->[0] );
		my $subject = lc( $captures->[1] );
		$subject =~ s/[\.\?\! ]+$//;	# Remove punctuation
		$subject =~ s/^(the|a|an) //;	# Remove articles, if they exist
		
		my $sort = "desc";
		my $op = "1";
		if ( $what and ( $what eq 'hates' or $what eq 'minused' or $what eq 'doesn\'t like' ) ) {
			$sort = "asc";
			$op = "-1";
		}

        my $sth = $self->database->handle->prepare("select user, total from (select user, sum(amount) as total from karma where subject = '$subject' and amount = $op group by user) order by total $sort");
		$sth->execute;

		my @people;
		my $row;
		while ( $row = $sth->fetchrow_arrayref() ) {
			my ( $user, $total ) = @$row;

			push( @people, { 'user' => $user, 'total' => $total } );
		}
		
		if ( scalar(@people) == 1 ) {
			my $num = abs( $people[0]->{'total'} );
			my $who = $people[0]->{'user'};

			my $howmuch = ( $num == 1 ? "once" : $num == 2 ? "twice" : "$num times" );

			if ( $who eq $message->from ) {
				return $message->from . ': It was YOU! ' . ucfirst($howmuch) . ".";
			} else {
				return $message->from . ': It was ' . $people[0]->{'user'} . ", $howmuch.";
			}
			
		#} elsif (scalar(@people) > 10) {
		#	return $message->from . ': More than 10 people, so nearly everyone.';
			
		} elsif ( scalar(@people) > 0 ) {
			my $peopleText = join( ', ', map { $_->{'user'} . " (" . $_->{'total'} . ")" } @people );
			my $sum = 0;
			$sum += $_->{'total'} foreach (@people);
			return $message->from . ": $peopleText = $sum";
			
		} else {
			return $message->from . ': Nobody!';
		}
	}
	
	return;
}

__PACKAGE__->meta->make_immutable;

1;
