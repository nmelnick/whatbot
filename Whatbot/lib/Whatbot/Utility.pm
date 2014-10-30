package Whatbot::Utility;
use strict;
use warnings;

use HTML::Strip;
use Encode;
use utf8;

# HTML::Strip does not inherently know anything about utf8, it seems to be
# a simpler XS translation. Since this series of lines appeared a lot, it is
# now moved to its own module.
sub html_strip {
	my ($to_strip) = @_;

	my $octets = encode_utf8($to_strip);
	utf8::downgrade($octets);
	my $strip = HTML::Strip->new( emit_spaces => 0, decode_entities => 1 );
	my $converted = $strip->parse($octets);
	$strip->eof;
	return decode_utf8($converted);
}

1;

=pod

=head1 NAME

Whatbot::Utility - Utility functions for whatbot

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
