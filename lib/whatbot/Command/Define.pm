###########################################################################
# whatbot/Command/Define.pm
###########################################################################
# Pulls a definition from google.com
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Define;
use Moose;
BEGIN { extends 'whatbot::Command' }

# modules! CPAN! I don't even have to code anymore.
use LWP::UserAgent ();
use URI::Escape qw(uri_escape);
use HTML::Entities qw(decode_entities);
use Lingua::EN::Sentence qw(get_sentences);
use HTML::Strip ();

has 'ua' => (
	is		=> 'ro',
	isa		=> 'LWP::UserAgent',
	default => sub { LWP::UserAgent->new; }
);

has 'stripper' => (
	is 		=> 'ro',
	isa		=> 'HTML::Strip',
	default => sub { HTML::Strip->new( emit_spaces => 0, decode_entities => 1 ); }
);

has 'error' => (
	is		=> 'rw',
	isa		=> 'Str',
	default	=> undef,
	reader	=> 'get_error',
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

        # things that suck
        $def =~ s/  / /g;
        $def =~ s/ ,/,/g;

        return $def . " (U)";
}

sub google {
        my ( $self, $phrase ) = @_;

        my $content = $self->get("http://www.google.com/search?q=define:!dongs!", $phrase);
        return undef unless $content;

        my $found = ($content =~ m!\G.*?<li>(.*?)<li>!gcs);
        return undef unless $found;

        my $def = $1;

        # things that suck
        $def =~ s/  / /g;
        $def =~ s/ ,/,/g;

        return $def . " (G)";
}


sub wikipedia {
	my ( $self, $phrase ) = @_;

	my $content = $self->get("http://en.wikipedia.org/wiki/Special:Search?search=!dongs!", $phrase);
	return undef unless $content;

	# In certain circumstances, a redirect will go to an anchor, which is done via javascript:
	my ($fragment) = ($content =~ m!^redirectToFragment\("\#([^"]+)"\);$!m);

	if ($fragment) {
		# wind forward through the content until we find the fragment
		my $dummy = ($content =~ m!a name="$fragment"!gs);
		# now, if it's there, \G (aka pos()) will be set to the fragment start
	}

RETRY:
	my $found = ($content =~ m!\G.*?<p>(.*?)</p>!gcs);
	return undef unless $found;
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
	return undef if ($first_p =~ /see Wikipedia:Searching\./);

	goto RETRY unless $first_p =~ /\./;

	my $sentences = get_sentences($first_p);

	if (!$sentences || (@$sentences < 1)) {
		$self->error("get_sentences failed on first paragraph from wikipedia");
		return undef;
	}

	my $def = $sentences->[0];

	# footnotes suck
	$def =~ s/\[\d+\]//g;

	# other things suck
	$def =~ s/  / /g;
	$def =~ s/ ,/,/g;
	$def =~ s/\(help·info\)//g;

	$def =~ s/\[citation needed\]//g; # this makes me want to stab people, just for the record

	return $def . " (W)";
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
		return $response->content;
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

	my ($def, $error);
        foreach my $func ( qw( urbandictionary wikipedia google ) ) {
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

1;
