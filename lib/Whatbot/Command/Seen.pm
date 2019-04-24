###########################################################################
# Whatbot/Command/Seen.pm
###########################################################################
# provides seen response and collection
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Seen;
use Moose;
use Whatbot::Command;
BEGIN { extends 'Whatbot::Command'; }

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
	$self->model('Seen')->seen( lc( $message->from ), $message->content );
	return;
}

sub seen : CommandRegEx('(.+)') {
    my ( $self, $message, $captures ) = @_;
	
	if ($captures) {
		my $user = $captures->[0];
		$user =~ s/[\?\!\.]+$//;
		my @users = ($user);
		my $aliases = $self->model('UserAlias')->related_users( lc($user) );
		push( @users, @$aliases ) if ($aliases);

		my $last;
		foreach my $user_alias (@users) {
			my $ret = $self->model('Seen')->seen( lc($user_alias) );
			if ( $ret and $ret->user ) {
				if ( not $last ) {
					$last = $ret;
				} elsif ( $ret->timestamp > $last->timestamp ) {
					$last = $ret;
				}
			}
		}

		if ($last) {
			return join(" ",
				$user,
				'was last seen' . ( $last->user ne lc($user) ? ' as ' . $last->user : '' ),
				'on',
				strftime('%Y-%m-%d at %H:%M:%S %Z', localtime( $last->timestamp )),
				'saying, "' . $last->message . '".'
			);
		} else {
			return 'I have not seen ' . $user . ' yet.';
		}
	}
}

__PACKAGE__->meta->make_immutable;

1;