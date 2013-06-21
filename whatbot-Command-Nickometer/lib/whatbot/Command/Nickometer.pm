###########################################################################
# whatbot/Command/Nickometer.pm
###########################################################################
# Called whenever it sees the word "nickometer".
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Nickometer;
use Moose;
BEGIN { extends 'whatbot::Command' }

use Math::Trig;
use namespace::autoclean;

our $VERSION = '0.1';

sub register {
	my ( $self ) = @_;
	
	$self->command_priority("Extension");
	$self->require_direct(0);
}

sub parse_message : CommandRegEx('(.+)') {
	my ( $self, $message, $captures ) = @_;
	
	my ($nickometer) = $captures->[0];
	if ($nickometer) {
		return $message->from . ": '" . $nickometer . "' is " . $self->do_nickometer($nickometer) . "% lame.";
	}
	return undef;
}

sub do_nickometer {
	my $self = shift;
	$_ = shift;

	# Deal with special cases (precede with \ to prevent de-k3wlt0k)
	my %special_cost = (
		'69'				=> 500,
		'dea?th'			=> 500,
		'dark'				=> 400,
		'n[i1]ght'			=> 300,
		'n[i1]te'			=> 500,
		'fuck'				=> 500,
		'sh[i1]t'			=> 500,
		'coo[l1]'			=> 500,
		'kew[l1]'			=> 500,
		'lame'				=> 500,
		'dood'				=> 500,
		'dude'				=> 500,
		'[l1](oo?|u)[sz]er'	=> 500,
		'[l1]eet'			=> 500,
		'e[l1]ite'			=> 500,
		'[l1]ord'			=> 500,
		'pron'				=> 1000,
		'warez'				=> 1000,
		'xx'				=> 100,
		'\[rkx]0'			=> 1000,
		'\0[rkx]'			=> 1000,
	);

	foreach my $special (keys %special_cost) {
		my $special_pattern = $special;
		my $raw = ($special_pattern =~ s/^\\//);
		my $nick = $_;
		unless ($raw) {
			$nick =~ tr/023457+8/ozeasttb/;
		}
		$self->punish(
			$special_cost{$special},
			"matched special case /$special_pattern/"
		) if ( $nick =~ /$special_pattern/i );
	}
	
	# Allow Perl referencing
	s/^\\([A-Za-z])/$1/;
	
	# Keep me safe from Pudge ;-)
	s/\^(pudge)/$1/i;

	# C-- ain't so bad either
	s/^C--$/C/;
	
	# Punish consecutive non-alphas
	s/([^A-Za-z0-9]{2,})
	 /my $consecutive = length($1);
		$self->punish($self->slow_pow(10, $consecutive), 
			"$consecutive total consecutive non-alphas")
			if $consecutive;
		$1
	 /egx;

	# Remove balanced brackets and punish for unmatched
	while (s/^([^()]*)	 (\(.*) (\)) ([^()]*)	 $/$1$3$5/x ||
	 s/^([^{}]*)	 (\{) (.*) (\}) ([^{}]*)	 $/$1$3$5/x ||
	 s/^([^\[\]]*) (\[) (.*) (\]) ([^\[\]]*) $/$1$3$5/x) 
	{
	}
	my $parentheses = tr/(){}[]/(){}[]/;
	$self->punish($self->slow_pow(10, $parentheses), 
		"$parentheses unmatched " .
			($parentheses == 1 ? 'parenthesis' : 'parentheses'))
		if $parentheses;

	# Punish k3wlt0k
	my @k3wlt0k_weights = (5, 5, 2, 5, 2, 3, 1, 2, 2, 2);
	for my $digit (0 .. 9) {
		my $occurrences = s/$digit/$digit/g || 0;
		$self->punish($k3wlt0k_weights[$digit] * $occurrences * 30,
			$occurrences . ' ' .
				(($occurrences == 1) ? 'occurrence' : 'occurrences') .
				" of $digit")
			if $occurrences;
	}

	# An alpha caps is not lame in middle or at end, provided the first
	# alpha is caps.
	my $orig_case = $_;
	s/^([^A-Za-z]*[A-Z].*[a-z].*?)[_-]?([A-Z])/$1\l$2/;
	
	# A caps first alpha is sometimes not lame
	s/^([^A-Za-z]*)([A-Z])([a-z])/$1\l$2$3/;
	
	# Punish uppercase to lowercase shifts and vice-versa, modulo 
	# exceptions above
	my $case_shifts = $self->case_shifts($orig_case);
	$self->punish($self->slow_pow(9, $case_shifts),
		$case_shifts . ' case ' .
			(($case_shifts == 1) ? 'shift' : 'shifts'))
		if ($case_shifts > 1 && /[A-Z]/);

	# Punish lame endings (TorgoX, WraithX et al. might kill me for this :-)
	$self->punish(50, 'last alpha lame') if $orig_case =~ /[XZ][^a-zA-Z]*$/;

	# Punish letter to numeric shifts and vice-versa
	my $number_shifts = $self->number_shifts($_);
	$self->punish($self->slow_pow(9, $number_shifts), 
		$number_shifts . ' letter/number ' .
			(($number_shifts == 1) ? 'shift' : 'shifts'))
		if $number_shifts > 1;

	# Punish extraneous caps
	my $caps = tr/A-Z/A-Z/;
	$self->punish($self->slow_pow(7, $caps), "$caps extraneous caps") if $caps;

	# Now punish anything that's left
	my $remains = $_;
	$remains =~ tr/a-zA-Z0-9//d;
	my $remains_length = length($remains);

	$self->punish(50 * $remains_length + $self->slow_pow(9, $remains_length),
		$remains_length . ' extraneous ' .
			(($remains_length == 1) ? 'symbol' : 'symbols'))
		if $remains;


	# Use an appropriate function to map [0, +inf) to [0, 100)
	my $percentage = 100 * 
		(1 + tanh(($self->{score}-400)/400)) * 
		(1 - 1/(1+$self->{score}/5)) / 2;

	my $digits = 2 * (2 - $self->round_up(log(100 - $percentage) / log(10)));

	return sprintf "%.${digits}f", $percentage;
}

sub case_shifts {
	my ( $self, $shifts ) = @_;
	# This is a neat trick suggested by freeside.	Thanks freeside!

	$shifts =~ tr/A-Za-z//cd;
	$shifts =~ tr/A-Z/U/s;
	$shifts =~ tr/a-z/l/s;

	return length($shifts) - 1;
}

sub number_shifts {
	my ( $self, $shifts ) = @_;

	$shifts =~ tr/A-Za-z0-9//cd;
	$shifts =~ tr/A-Za-z/l/s;
	$shifts =~ tr/0-9/n/s;

	return length($shifts) - 1;
}

sub slow_pow {
	my ( $self, $x, $y ) = @_;

	return $x ** $self->slow_exponent($y);
}

sub slow_exponent {
	my ( $self, $x ) = @_;

	return 1.3 * $x * (1 - atan($x/6) *2/pi);
}

sub round_up {
	my ( $self, $float ) = @_;

	return int($float) + ((int($float) == $float) ? 0 : 1);
}

sub punish {
	my ( $self, $damage, $reason ) = @_;

	return unless $damage;
	$self->{'score'} += $damage;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

whatbot::Command::Nickometer - Determine how lame a nick is.

=head1 DESCRIPTION

whatbot::Command::Nickometer uses a "complex" algorithm to determine how lame
a nick is. Ported from infobot's nickometer.pl, (c)1998 Adam Spiers
<adam.spiers@new.ox.ac.uk>.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
