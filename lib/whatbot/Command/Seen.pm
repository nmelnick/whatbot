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
use namespace::autoclean;

sub register {
	my ($self) = @_;
	
	$self->command_priority('Core');
	$self->require_direct(0);
}

sub store_user : Monitor {
	my ( $self, $message ) = @_;
	
	return if ( $message->invisible );
	$self->model('seen')->seen( lc( $message->from ), $message->content );
	return;
}

sub seen : CommandRegEx('(.+)') {
    my ( $self, $message, $captures ) = @_;
	
	if ($captures) {
		my $user = $captures->[0];
		$user =~ s/[\?\!\.]+$//;
		my $ret = $self->model('seen')->seen( lc($user) );
		if ( $ret and $ret->user ) {
			return join(" ",
				$user,
				'was last seen on ',
				strftime('%Y-%m-%d at %H:%M:%S', localtime( $ret->timestamp )),
				'saying, "' . $ret->message . '".'
			);
		} else {
			return 'I have not seen ' . $user . ' yet.';
		}
	}
}

__PACKAGE__->meta->make_immutable;

1;