###########################################################################
# whatbot/Command/Tell.pm
###########################################################################
# tell someone something
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Tell;
use Moose;
BEGIN { extends 'whatbot::Command' }

sub register {
	my ($self) = @_;

	$self->command_priority('Extension');
	$self->require_direct(0);
	
	return;
}

sub request_tell : CommandRegEx('(.*)') : StopAfter {
	my ( $self, $message, $captures ) = @_;

	return unless ( $captures and @$captures );
	my ( $username, @captures ) = split( /\s+/, shift(@$captures) );
	$username = lc($username);
	my $tell = join( ' ', @captures );
	$tell   =~ s/|\[\[\]]//g;
	$tell   =~ s/|\]//g;
	$tell   =~ s/^that //;
	$tell   =~ s/^s?he is/you are/;
	$tell   =~ s/^s?he/you/;
	$tell   =~ s/^you ([a-z]+?)s$/you $1/;
	
	# Set from
	$tell = join( '|[', $message->from, $tell );
	
	if ( my $previous = $self->model('Soup')->get($username) ) {
		$tell = $previous . '|]' . $tell;
	}
	$self->model('Soup')->set( $username, $tell );
	
	return 'OK, ' . $message->from . '.';
}

sub do_tell : Event('enter') {
	my ( $self, $user ) = @_;
	
	$user = lc($user);
	if ( my $response = $self->model('Soup')->get($user) ) {
		my @reply;
		my @response = split( /\|\]/, $response );
		foreach my $tell ( @response ) {
			my ( $from, $to_tell ) = split( /\|\[/, $tell );
			push( @reply, sprintf( '%s, %s wants you to know %s%s', $user, $from, $to_tell, ( $to_tell =~ /[\.\?!]$/ ? '' : '.' ) ) );
		}
		$self->model('Soup')->clear($user);
		return \@reply;
	}

	return;
}

1;
