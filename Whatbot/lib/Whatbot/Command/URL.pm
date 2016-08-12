###########################################################################
# Whatbot/Command/URL.pm
###########################################################################
# keeps track of URLs, URL information, and history
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::URL;
use Moose;
use Whatbot::Command;
BEGIN { extends 'Whatbot::Command'; }

use POSIX qw(strftime);
use namespace::autoclean;

sub register {
	my ($self) = @_;

	$self->command_priority('Extension');
	$self->require_direct(0);
	return;
}

sub store_url : GlobalRegEx('.*?((https|http|ftp|feed):\/\/[^\s]+).*') {
	my ( $self, $message, $captures ) = @_;

	return if ( $message->invisible );

	my $url = $captures->[0];
	my $title = $self->model('URL')->url_title( $url, $message->from );

	return '[URL: ' . $title . ']' if ($title);
	return;
}

sub last : Command {
	my ( $self, $message ) = @_;

	my $row = $self->model('URL')->search_one({
		'_order_by' => 'url_id DESC'
	});
	if ($row) {
		my $url_domain = $self->model('URL')->table_domain->find( $row->domain_id );
		my $url_protocol = $self->model('URL')->table_protocol->find( $row->protocol_id );

		return [
			sprintf( '[URL: %s://%s/%s ]', $url_protocol->name, $url_domain->name, $row->path ),
			sprintf( '(From %s on %s - "%s")', $row->user, strftime( '%Y-%m-%d at %H:%m', localtime( $row->timestamp ) ), $row->title )
		];
	}
}

sub count : Command {
	my ( $self, $message ) = @_;

	my $urls = $self->model('URL')->count();
	my $domains = $self->model('URL')->table_domain->count();

	return sprintf( 'There are %d URLs attached to %d domains stored.', $urls, $domains );
}

sub search : Command {
	my ( $self, $message, $captures ) = @_;

	my $search_text = join( ' ', @$captures );
	return unless ($search_text);

	my @response;
	my $results = $self->model('URL')->search({
		'title' => { 'LIKE' => '%' . $search_text . '%' }
	});
	if ( @$results > 3 ) {
		push( @response, 'There were ' . @$results . ' result(s) found, showing the first 3.' );
	}
	foreach (0..2) {
		next unless ( $results->[$_] );
		my $row = $results->[$_];
		my $url_domain = $self->model('URL')->table_domain->find( $row->domain_id );
		my $url_protocol = $self->model('URL')->table_protocol->find( $row->protocol_id );

		push(
			@response,
			sprintf( '%d) %s://%s%s - "%s"', ( $_ + 1 ), $url_protocol->name, $url_domain->name, $row->path, $row->title )
		);
	}

	return ( @response ? \@response : 'No results for "' . $search_text . '" found.' );
}

sub help {
	my ( $self ) = @_;

	return [
		'URL is a URL management module for whatbot. All canonical URLs seen ' .
		'in any open channels or chats are stored with the title of the found ' .
		'page, user information, and timestamp. To query URLs, start the ' .
		'command with "url" and then one of the following: ',
		' * "last" to show the last URL given, along with the user, title and time.',
		' * "search" (text) to search titles of past URLs.'
	];
}

__PACKAGE__->meta->make_immutable;

1;
