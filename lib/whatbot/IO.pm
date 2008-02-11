###########################################################################
# whatbot/IO.pm
###########################################################################
#
# Base class for whatbot IO classes
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::IO;
use Moose;
extends 'whatbot::Component';
use whatbot::Message;

has 'myConfig' => (
	is	=> 'rw',
	isa	=> 'HashRef'
);

has 'name' => (
	is	=> 'rw',
	isa	=> 'Str'
);

has 'me' => (
	is	=> 'rw',
	isa	=> 'Str'
);

sub BUILD {
	my ($self) = @_;
	
	unless (defined $self->myConfig) {
		die "No configuration found for " . ref($self);
	}
}

sub notify {
	my ($self, $message) = @_;
	
	$self->log->write("(" . $self->name . ") " . $message) unless (defined $self->myConfig->{silent});
}

sub connect {
	my ($self) = @_;
	
}

sub disconnect {
	my ($self) = @_;
	
}

sub eventUserEnter {
	my ($self) = @_;
	
}

sub eventUserLeave {
	my ($self) = @_;
	
}

sub eventMessagePublic {
	my ($self, $from, $content) = @_;
	
	if ($from ne $self->me) {
		my $message;
		if (ref($content) eq 'whatbot::Message') {
			$message = $content;
			$self->notify("[PUB] <$from> " . $content->content);
		} else {
			$self->notify("[PUB] <$from> $content");
			$message = new whatbot::Message(
				from			=> $from,
				to				=> "public",
				content			=> $content,
				timestamp		=> time,
				me				=> $self->me,
				baseComponent	=> $self->parent->baseComponent
			);
		}
		$self->parseResponse($self->controller->handle($message));
	}
}

sub eventMessagePrivate {
	my ($self, $from, $content) = @_;
	
	$self->notify("[PRI] <$from> $content");
	if ($from ne $self->me) {
		my $message = new whatbot::Message(
			from			=> $from,
			to				=> $self->me,
			content			=> $content,
			timestamp		=> time,
			isPrivate		=> 1,
			me				=> $self->me,
			baseComponent	=> $self->parent->baseComponent
		);
		$self->parseResponse($self->controller->handle($message));
	}
	
}

sub eventAction {
	my ($self, $from, $content) = @_;
	
	$self->notify("[ACT] $from $content");
}

sub sendMessage {
	my ($self, $messageObj) = @_;
	
}

sub parseResponse {
	my ($self, $messageObj) = @_;
	
	return undef unless (defined $messageObj);
	$self->sendMessage($messageObj);
}

1;