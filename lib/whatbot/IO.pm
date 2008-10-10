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

has 'my_config' => (
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
	my ( $self ) = @_;
	
	unless (defined $self->my_config) {
		die "No configuration found for " . ref($self);
	}
}

sub notify {
	my ( $self, $message ) = @_;
	
	$self->log->write( '(' . $self->name . ') ' . $message )
	    unless ( defined $self->my_config->{'silent'} );
}

sub connect {
	my ( $self ) = @_;
	
}

sub disconnect {
	my ( $self ) = @_;
	
}

sub eventUserEnter {
	my ( $self ) = @_;
	
}

sub eventUserLeave {
	my ( $self ) = @_;
	
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
				base_component	=> $self->parent->base_component
			);
		}
		$self->parseResponse( $self->controller->handle($message) );
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
			is_private		=> 1,
			me				=> $self->me,
			base_component	=> $self->parent->base_component
		);
		$self->parseResponse( $self->controller->handle($message) );
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
	my ($self, $messages) = @_;
	
	return undef unless ( defined $messages );
	foreach my $message ( @{$messages} ) {
	    $self->sendMessage($message);
	}
}

1;