###########################################################################
# Whatbot/Command/Weather/SourceRole.pm
###########################################################################
# Role representing a weather source
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

role Whatbot::Command::Weather::SourceRole {
	use LWP::UserAgent;

	has 'my_config' => (
		is  => 'ro',
		isa => 'HashRef',
	);

	has 'ua' => (
		is		=> 'ro',
		isa		=> 'LWP::UserAgent',
		default => sub { LWP::UserAgent->new( 'timeout' => 15 ); }
	);

	method get_current( Str $location ) {
		die 'Source does not implement get_current';
		return;
	}

	method get_forecast( Str $location ) {
		die 'Source does not implement get_forecast';
		return;
	}

}

1;

=pod

=head1 NAME

Whatbot::Command::Weather::SourceRole - Role for Weather Sources

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
