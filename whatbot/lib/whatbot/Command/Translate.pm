###########################################################################
# whatbot/Command/Translate.pm
###########################################################################
# Utilizes babelfish to provide translation
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Translate;
use Moose;
BEGIN { extends 'whatbot::Command' }

use WWW::Babelfish;
use Encode;
use namespace::autoclean;

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub parse_message : CommandRegEx('(from [A-z]* )?to ([A-z]*?) (.*)( using [A-z]*)?') {
	my ( $self, $message, $captures ) = @_;
	
	if ($captures) {
		my $from = 'English';
		my $using = 'Yahoo';
		if ( $captures->[0] ) {
			$from = $1;
			$from =~ s/from //;
			$from =~ s/ //g;
		}
		if ( $captures->[3] ) {
			$from = $4;
			$from =~ s/using //;
			$from =~ s/ //g;
		}
		return $self->translate( $from, $captures->[1], $captures->[2], $using );
	}
}

sub languages : Command {
	my ( $self, $using ) = @_;
	
	my $translator = $self->get_translator($using);
	return 'Translation service is down' if (!defined $translator);
	
	my @languages = $translator->languages();
	return 'Something is not right.' unless (@languages);
	$languages[scalar(@languages) - 1] = 'and ' . $languages[scalar(@languages) - 1];
	return 'I can translate ' . join(', ', @languages) . '.';
}

sub help {
    my ( $self ) = @_;
    
    return 'Translate uses Babelfish to machine translate text in other languages. ' . $self->languages();
}

sub get_translator {
	my ( $self, $using ) = @_;
	
	return WWW::Babelfish->new(
		'service'	=> 'Yahoo',
		'agent' 	=> 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10'
	);
}

sub translate {
	my ( $self, $from, $to, $message, $using ) = @_;
	
	my $translator = $self->get_translator($using);
	return 'Translation service is down' if (!defined $translator);
	
	$from = ucfirst(lc($from));
	$to = ucfirst(lc($to));
	
	if (!defined $translator->languagepairs->{$from}) {
		return 'I do not know how to translate from "' . $from . '".';
	}
	if (!defined $translator->languagepairs->{$from}->{$to}) {
		my @languages = keys %{$translator->languagepairs->{$from}};
		$languages[scalar(@languages) - 1] = 'and ' . $languages[scalar(@languages) - 1];
		return 'I do not know how to translate from "' . $from . '" to "' . $to . '".' .
		 	   ' I can translate ' . $from . ' to ' . join(', ', @languages);
	}
	
	my $text = $translator->translate(
		'source' 		=> $from,
		'destination' 	=> $to,
		'text' 			=> $message
	);
	warn $translator->error;
	if ($text) {
		return 'Translation: ' . $text;
	} else {
		return 'Sorry, I had an error trying to translate that.';
	}
}

__PACKAGE__->meta->make_immutable;

1;