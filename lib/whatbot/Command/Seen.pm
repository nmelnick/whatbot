###########################################################################
# whatbot/Command/Seen.pm
###########################################################################
# provides seen response and collection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Seen;
use Moose;
BEGIN { extends 'whatbot::Command'; }

use POSIX qw(strftime);

sub register {
	my ($self) = @_;
	
	$self->command_priority('Core');
	$self->require_direct(0);
}

sub store_user : Monitor {
	my ( $self, $message ) = @_;
	
	$self->store->seen( lc($message->from), $message->content );
	return;
}

sub seen : CommandRegEx('(.+)') {
    my ( $self, $message, $captures ) = @_;
	
	if ($captures) {
		my $user = $captures->[0];
		$user =~ s/[\?\!\.]+$//;
		my $ret = $self->store->seen( lc($user) );
		if ( defined $ret and $ret->{'user'} ) {
			return join(" ",
				$user,
				'was last seen on ',
				strftime('%Y-%m-%d at %H:%M:%S', localtime( $ret->{'timestamp'} )),
				'saying, "' . $ret->{'message'} . '".'
			);
		} else {
			return 'I have not seen ' . $user . ' yet.';
		}
	}
}

1;