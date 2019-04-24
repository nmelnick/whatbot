###########################################################################
# Whatbot/Command/Karma.pm
###########################################################################
# Similar to infobot's karma system, this is part of the core bot
# functionality
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Karma;
use Moose;
use Whatbot::Command;
BEGIN { extends 'Whatbot::Command'; }
use namespace::autoclean;

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
	my $nick = $self->model('UserAlias')->canonical_user( $message->from );

	my $karmas;
	if ($verb eq 'like') {
		$karmas = $self->model('karma')->top_n($who, 10);
	} else {
		$karmas = $self->model('karma')->bottom_n($who, 10);
	}

	if (!$karmas or !@$karmas) {
		return "$nick: I don't know what $who ${verb}s.";
	}

	# filter non-liked or non-hated things (happens with people with few karma entries)
	@$karmas = grep { $verb eq 'like'? ($_->{'sum'} > 0) : ($_->{'sum'} < 0)  } @$karmas;

	my @results = map { $_->{'subject'} . ' (' . $_->{'sum'} . ')' } @$karmas;

	return "$who ${verb}s: " . join ( ', ', @results );
}

sub info : Command {
	my ( $self, $message, $captures ) = @_;

	if ($captures) {
		my $phrase = lc( join( ' ', @$captures ) );
		my $user = $self->model('UserAlias')->canonical_user($phrase);
		my $karma_info = $self->model('karma')->get_extended($user);
		if (
			defined $karma_info
			and ( $karma_info->{'Increments'} != 0 or $karma_info->{'Decrements'} != 0 )
		) {
			my $rocks = sprintf( "%0.1f", 100 * ($karma_info->{'Increments'} / ($karma_info->{'Increments'} + $karma_info->{'Decrements'})) );
			my $sucks = sprintf( "%0.1f", 100 * ($karma_info->{'Decrements'} / ($karma_info->{'Increments'} + $karma_info->{'Decrements'})) );
			return 
				"$phrase" . ( $phrase ne $user ? ' (as ' . $user .')' : '' ) . " has had " . $karma_info->{'Increments'} . " increments and " . $karma_info->{'Decrements'} . " decrements, for a total of " . ($karma_info->{'Increments'} - $karma_info->{'Decrements'}) . 
				". $phrase " . ($rocks > $sucks ? "$rocks% rocks" : "$sucks% sucks") . 
				". Last change was by " . $karma_info->{'Last'}->[0] . ", who gave it a " . ($karma_info->{'Last'}->[1] == 1 ? '++' : '--') . ".";
		} else {
			return "$phrase has no karma";
		}
	}
}

sub parse_message : GlobalRegEx('[\+\-]{2}') {
	my ( $self, $message ) = @_;

	my $content = $message->content;
	while ( $content =~ m/\(([^\-\+]+?)\)([\+\-]{2})/g ) {
		# more than one word
		my $phrase = $1;
		my $op = $2;
		$self->parse_operator( $phrase, $op, $message->from );
	}
	while ( $content =~ m/([^ \-\+\)\(]+)([\+\-]{2})/g ) {
		# one word
		my $word = $1;
		my $op = $2;
		$self->parse_operator( $word, $op, $message->from );
	}

	return;
}

sub karma : CommandRegEx('(.*)') {
	my ( $self, $message, $captures ) = @_;

	if ($captures) {
		my $phrase = $captures->[0];
		return if ( $phrase =~ /^info/ );   # Hack to pass through if requesting info
		my $user = $self->model('UserAlias')->canonical_user($phrase);
		my $karma = $self->model('karma')->get($user);
		if ( $karma and $karma != 0 ) {
			return $phrase . ( $phrase ne $user ? ' (as ' . $user .')' : '' ) . " has a karma of $karma";
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
	return if ( $subject eq lc($from) );
	$subject = $self->model('UserAlias')->canonical_user($subject);

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

__PACKAGE__->meta->make_immutable;

1;
