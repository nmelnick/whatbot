###########################################################################
# whatbot/Command/Translate.pm
###########################################################################
# Utilizes babelfish to provide translation
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Translate;
use Moose;
extends 'whatbot::Command';
use WWW::Babelfish;
use Encode;

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Extension");
	$self->listenFor([
		qr/^translate (from [A-z]* )?to ([A-z]*?) (.*)( using [A-z]*)?/i,
		qr/^translation languages/i,
	]);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	if ($messageRef->content =~ $self->listenFor->[0]) {
		my $from = "English";
		my $using = "Babelfish";
		if ($1) {
			$from = $1;
			$from =~ s/from //;
			$from =~ s/ //g;
		}
		if ($4) {
			$from = $4;
			$from =~ s/using //;
			$from =~ s/ //g;
		}
		return translate($from, $2, $3, $using);
	} elsif ($messageRef->content =~ $self->listenFor->[1]) {
		return languages();
	}
}

sub getTranslator {
	my ($using) = @_;
	
	return new WWW::Babelfish(
		service	=> ($using or "Babelfish"),
		agent 	=> 'Mozilla/8.0'
	);
}

sub languages {
	my ($using) = @_;
	
	my $translator = getTranslator($using);
	return "Translation service is down" if (!defined $translator);
	
	my @languages = $translator->languages;
	$languages[scalar(@languages) - 1] = "and " . $languages[scalar(@languages) - 1];
	return "I can translate " . join(", ", @languages) . ".";
}

sub translate {
	my ($from, $to, $message, $using) = @_;
	
	my $translator = getTranslator($using);
	return "Translation service is down" if (!defined $translator);
	
	$from = ucfirst(lc($from));
	$to = ucfirst(lc($to));
	
	if (!defined $translator->languagepairs->{$from}) {
		return "I don't know how to translate from '" . $from . "'.";
	}
	if (!defined $translator->languagepairs->{$from}->{$to}) {
		my @languages = keys %{$translator->languagepairs->{$from}};
		$languages[scalar(@languages) - 1] = "and " . $languages[scalar(@languages) - 1];
		return "I don't know how to translate from '" . $from . "' to '" . $to . "'." .
		 	   " I can translate " . $from . " to " . join(", ", @languages);
	}
	
	$message = encode("utf8", $message);
	my $text = $translator->translate(
		'source' 		=> $from,
		'destination' 	=> $to,
		'text' 			=> $message
	);
	if ($text) {
		return "Translation: " . Encode::encode_utf8($text);
	} else {
		return "Sorry, I had an error trying to translate that.";
	}
}

1;