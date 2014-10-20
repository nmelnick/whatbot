###########################################################################
# Whatbot/Command/Define.pm
###########################################################################
# Pulls a definition from google.com
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Define;
use Moose;
BEGIN { extends 'Whatbot::Command' }

# modules! CPAN! I don't even have to code anymore.
use LWP::UserAgent ();
use URI::Escape qw(uri_escape);
use HTML::Entities qw(decode_entities);
use Lingua::EN::Sentence qw(get_sentences);
use HTML::Strip ();
use namespace::autoclean;

has 'ua' => (
	is      => 'ro',
	isa     => 'LWP::UserAgent',
	default => sub { LWP::UserAgent->new; }
);

has 'stripper' => (
	is      => 'ro',
	isa     => 'HTML::Strip',
	default => sub { HTML::Strip->new( emit_spaces => 0, decode_entities => 1 ); }
);

has 'error' => (
	is  => 'rw',
	isa => 'Maybe[Str]',
);

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	$self->ua->agent('Mozilla/5.0');
}

sub parse_message : CommandRegEx('(.*)') {
	my ( $self, $message, $captures ) = @_;

	my ($phrase) = ( @$captures );
	return "what" unless $phrase;

	my $def = $self->_parse($phrase);

	return $def if $def;

	return $message->from . ": No definition for $phrase.";
}

sub urbandictionary {
	my ( $self, $phrase ) = @_;

	my $content = $self->get("http://www.urbandictionary.com/define.php?term=!dongs!", $phrase);
	return undef unless $content;

RETRY:
	my $found = ($content =~ m!\G.*?<div class='definition'>(.*?)</div>!gcs);
	return undef unless $found;
	my $first_p = $1;

	# get rid of <sup></sup> before the tags are gone, because <sup>?</sup>
	# (for example) messes with sentence structure
	$first_p =~ s!<sup>.*?</sup>!!g;

	$first_p = $self->stripper->parse($first_p);
	$self->stripper->eof;

	goto RETRY unless $first_p;
	
	my $sentences = get_sentences($first_p);

	if (!$sentences || (@$sentences < 1)) {
		$self->error("get_sentences failed on first paragraph from urban dictionary");
		return undef;
	}

	my $def = $sentences->[0];
	if ($def =~ /^\d+\.\s*$/) {
	   # Lingua::EN thinks "1." is a sentence. It is not.
	   $def .= " " . $sentences->[1];
	}

	# things that suck
	$def =~ s/  / /g;
	$def =~ s/ ,/,/g;

	return $def . " (UD)";
}

sub google {
	my ( $self, $phrase ) = @_;

	my $content = $self->get("http://www.google.com/search?q=define:!dongs!", $phrase);
	return undef unless $content;

	my $found = ($content =~ m!\G.*?<li>(.*?)<br>!gcs);
	return undef unless $found;

	my $def = $1;

	# things that suck
	$def =~ s/  / /g;
	$def =~ s/ ,/,/g;

	return $def . " (GG)";
}


sub wikipedia {
	my ( $self, $phrase ) = @_;

	my $content = $self->get("http://en.wikipedia.org/wiki/Special:Search?search=!dongs!", $phrase);
	return unless $content;

	# In certain circumstances, a redirect will go to an anchor, which is done via javascript:
	my ($fragment) = ($content =~ m!^redirectToFragment\("\#([^"]+)"\);$!m);

	if ($fragment) {
		# wind forward through the content until we find the fragment
		my $dummy = ($content =~ m!a name="$fragment"!gs);
		# now, if it's there, \G (aka pos()) will be set to the fragment start
	}

RETRY:
	my $found = ($content =~ m!\G.*?<p>(.*?)</p>!gcs);
	return unless $found;
	my $first_p = $1;

	# get rid of <sup></sup> before the tags are gone, because <sup>?</sup>
	# (for example) messes with sentence structure
	$first_p =~ s!<sup>.*?</sup>!!g;

	$first_p = $self->stripper->parse($first_p);
	$self->stripper->eof;
	
	goto RETRY unless $first_p;
	
	if ($first_p =~ /may refer to:/) {
		return "Multiple definitions for $phrase - be more specific.";
	}
	return if ( $first_p =~ /see Wikipedia:Searching\./ or $first_p =~ /You may create the page/ );

	goto RETRY unless $first_p =~ /\./;

	my $sentences = get_sentences($first_p);

	if (!$sentences || (@$sentences < 1)) {
		$self->error("get_sentences failed on first paragraph from wikipedia");
		return;
	}

	my $def = $sentences->[0];

	# footnotes suck
	$def =~ s/\[\d+\]//g;

	# other things suck
	$def =~ s/  / /g;
	$def =~ s/ ,/,/g;
	$def =~ s/\(help·info\)//g;

	$def =~ s/\[[^\]]+\]//g;

	return $def . " (WP)";
}

sub get {
	my ( $self, $url, $phrase ) = @_;

	$phrase = uri_escape($phrase);
	$phrase =~ s/\%20/+/g;
	$url =~ s/!dongs!/$phrase/g;

	my $response = $self->ua->get($url);

	if (!$response->is_success) {
		warn($response->status_line);
		$self->error("Error: " . $response->status_line);
		return undef;
	}
	else {
		return $response->decoded_content;
	}
}

# copy value, clear error, return.
sub get_error {
	my ( $self ) = shift;

	my $tmp = $self->{'error'};
	$self->{'error'} = undef;
	return $tmp;
}

sub _parse {
	my ( $self, $phrase ) = @_;

	my @default_sources;
	if ( !$self->my_config or !exists($self->my_config->{sourcelist}) ) {
		@default_sources = qw(urbandictionary google wikipedia);
	} else {
		@default_sources = split / /, $self->my_config->{sourcelist};
	}

	my @sources;
	$_ = $phrase;

	foreach my $src (@default_sources) {
		if (s/\s*\(\s*$src\s*\)\s*$//) {
			@sources = ($src);
			last;
		}
		push @sources, $src unless (s/\s*!$src\s*//);
	}

	$phrase = $_;

	my ($def, $error);
	foreach my $func (@sources) {
		{ 
			no strict 'refs';
			$def = $self->$func($phrase);
		}
		return $def if $def;

		$error = $self->error;
		return $error if $error;
	}
	
	return undef;
}

__PACKAGE__->meta->make_immutable;

1;
