###########################################################################
# Message.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Message - Wrapper class for whatbot message passing

=head1 SYNOPSIS

 use Whatbot::Message;
 
 my $message = Whatbot::Message->new(
   'from'    => $me,
   'to'      => 'a_user',
   'content' => 'test message'
 );

=head1 DESCRIPTION

Whatbot::Message is a container class for incoming and outgoing messages. Each
whatbot component, when sending or receiving a message via a Whatbot::IO class
will pass these objects, and messages sent through a Whatbot::Command is
encouraged to use these objects. Messages sent without this class will be
converted during the IO transaction.

=head1 PUBLIC ACCESSORS

=over 4

=item from

User or entity the message is from

=item to

User or entity the message is to

=item text

The text body of the message, which may contain tags as {!tag=value}.

=item content

Content of the message. This method is deprecated, but backwards compatible, so
recognized tags are stripped to fallback form.

=item timestamp

Timestamp of the message, in unix time.

=item is_private

Boolean (1/0), if the message was private or posted in a public channel.

=item is_direct

Boolean (1/0), if the message called the bot out by name

=item invisible

Boolean (1/0), if this message should not be processed by seen or other monitors.

=item me

String value of the bot's username.

=item origin

String containing the IO target signature, name:to. So, for an IRC server called
irc.example.org, channel #foo, this would be IRC_irc.example.org:#foo.

=back

=head1 METHODS

=over 4

=cut

class Whatbot::Message extends Whatbot::Component {
	use Encode;

	has 'from'          => ( is => 'rw', isa => 'Str', required => 1 );
	has 'to'            => ( is => 'rw', isa => 'Str', required => 1 );
	has 'reply_to'      => ( is => 'rw', isa => 'Str', required => 0 );
	has 'content'       => ( is => 'rw', isa => 'Str', required => 0, trigger => \&check_content );
	has 'text'          => ( is => 'rw', isa => 'Str', required => 0, trigger => \&check_text );
	has 'timestamp'     => ( is => 'rw', isa => 'Int', default => sub { time } );
	has 'is_direct'     => ( is => 'rw', isa => 'Int', default => 0 );
	has 'me'            => ( is => 'rw', isa => 'Str' );
	has 'origin'        => ( is => 'rw', isa => 'Str' );
	has 'invisible'     => ( is => 'rw', isa => 'Bool', default => 0 );

	method BUILD(...) {
		my $me = $self->me;

		# Determine if the message is talking about me
		if ( defined $me ) {
			if ( $self->text =~ /, ?$me[\?\!\. ]*?$/i ) {
				my $content = $self->text;
				$content =~ s/, ?$me[\?\!\. ]*?$//i;
				$self->text($content);
				$self->is_direct(1);
			
			} elsif ( $self->text =~ /^$me[\:\,\- ]+/i ) {
				my $content = $self->text;
				$content =~ s/^$me[\:\,\- ]+//i;
				$self->text($content);
				$self->is_direct(1);
			
			} elsif ( $self->text =~ /^$me \-+ /i ) {
				my $content = $self->text;
				$content =~ s/^$me \-+ //i;
				$self->text($content);
				$self->is_direct(1);
			
			}
		}

		$self->is_direct(1) if ( $self->is_private );
	}

=item content_utf8()

Return message content as converted by encode_utf8.

=cut

	method content_utf8() {
		return Encode::encode_utf8( $self->content );
	}

=item text_utf8()

Return message text as converted by encode_utf8.

=cut

	method text_utf8() {
		return Encode::encode_utf8( $self->text );
	}

=item is_private()

Determine if message is a private message, by checking if "to" matches "me".

=cut

	method is_private() {
		return ( $self->me ? ( $self->to eq $self->me ) : 0 );
	}

	method check_content( Str $content, ... ) {
		$content =~ s/^\s+//;
		$content =~ s/\s+$//;
		$self->{'content'} = $content;
		$self->text($content);
	}

	method check_text( Str $text, ... ) {
		$text =~ s/^\s+//;
		$text =~ s/\s+$//;
		$self->{'text'} = $text;
		$text =~ s/\{!user=(.*?)\}/$1/g;
		$self->{'content'} = $text;
	}

=item reply( \%overrides )

Generate a Whatbot::Message in reply to the current message. If is_private is
true, to will be set to the originator, otherwise, it will be set to the public
context for public IO. Optionally handles an override hashref to preset fields,
similar to the new constructor.

=cut

	method reply ( HashRef $overrides? ) {
		my $message = Whatbot::Message->new({
			'from'    => $self->me,
			'to'      => $self->reply_to || ( $self->is_private ? $self->from : $self->to ),
			'me'      => $self->me,
			'content' => '',
		});
		foreach my $key ( keys %$overrides ) {
			$message->$key( $overrides->{$key} );
		}
		return $message;
	}

=item clone()

Return a new Whatbot::Message with the same content as the current message.
References inside the object are reused, not duplicated.

=cut

	method clone() {
		return Whatbot::Message->new( { %$self } );
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
