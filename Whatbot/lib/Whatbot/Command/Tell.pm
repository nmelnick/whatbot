###########################################################################
# Whatbot/Command/Tell.pm
###########################################################################
# tell someone something
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Tell;
use Moose;
BEGIN { extends 'Whatbot::Command' }
use namespace::autoclean;

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
	my $tell = join( ' ', @captures );
	$tell   =~ s/|\[\[\]]//g;
	$tell   =~ s/|\]//g;
	$tell   =~ s/^that //;
	$tell   =~ s/^s?he is/you are/;
	$tell   =~ s/^s?he/you/;
	$tell   =~ s/^you ([a-z]+?)s$/you $1/;
	
	# Set from
	$tell = join( '|[', $message->from, $tell );
	
	my $stored_username = $message->to . '|' . lc($username);
	if ( my $previous = $self->model('Soup')->get($stored_username) ) {
		my @tells = split( /\|\]/, $previous );
		foreach (@tells) {
			if ( $_ eq $tell ) {
				return 'You are already telling that to ' . $username . ', ' . $message->from . '.';
			}
		}
		$tell = $previous . '|]' . $tell;
	}
	$self->model('Soup')->set( $stored_username, $tell );
	
	return 'OK, ' . $message->from . '.';
}

sub do_tell : Event('enter') : Event('user_change') {
	my ( $self, $target, $event_info ) = @_;

    my ( $io, $context ) = split( /:/, $target );
    my $user = $event_info->{'nick'};
	my $search_user = lc($user);
	my $query = join( '|', $context, $search_user );
	if ( my $response = $self->model('Soup')->get($query) ) {
		my @reply;
		my @response = split( /\|\]/, $response );
		foreach my $tell ( @response ) {
			my ( $from, $to_tell ) = split( /\|\[/, $tell );
			push(
				@reply,
				sprintf( '%s, %s wants you to know %s%s', $user, $from, $to_tell, ( $to_tell =~ /[\.\?!]$/ ? '' : '.' ) )
			);
		}
		$self->model('Soup')->clear($query);
		return \@reply;
	}

	return;
}

sub query_tell : GlobalRegEx('^what are you telling ([^\s\?]+)') {
	my ( $self, $message, $captures ) = @_;
	
	my $search_user = lc( $captures->[0] );
	return unless ($search_user);

	if ( my $response = $self->model('Soup')->get( join( '|', $message->to, $search_user ) ) ) {
		my @reply;
		my @response = split( /\|\]/, $response );
		foreach my $tell ( @response ) {
			my ( $from, $to_tell ) = split( /\|\[/, $tell );
			push( @reply, sprintf( 'Telling: %s wants %s to know "%s%s"', $from, $captures->[0], $to_tell, ( $to_tell =~ /[\.\?!]$/ ? '' : '.' ) ) );
		}
		return \@reply;
	} else {
		return 'Nothing, ' . $message->from . '.';
	}
}

__PACKAGE__->meta->make_immutable;

1;
