###########################################################################
# whatbot/Command/Seen.pm
###########################################################################
# provides seen response and collection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Seen;
use Moose;
extends 'whatbot::Command';
use POSIX qw(strftime);

sub register {
	my ($self) = @_;
	
	$self->command_priority("Core");
	$self->listen_for("");
	$self->require_direct(0);
}

sub parse_message {
	my ($self, $messageRef) = @_;
	
	if ($messageRef->content =~ /^seen (.*)/i) {
		my $user = $1;
		$user =~ s/[\?\!\.]+$//;
		my $ret = $self->store->seen(lc($user));
		if (defined $ret and $ret->{user}) {
			return join(" ",
				$user,
				"was last seen",
				strftime("on %Y-%m-%d at %H:%M:%S", localtime($ret->{timestamp})),
				"saying, \"" . $ret->{message} . "\"."
			);
		} else {
			return "I haven't seen $user yet.";
		}
	} else {
		$self->store->seen(lc($messageRef->from), $messageRef->content);
	}
	
	return undef;
}

1;