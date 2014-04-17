###########################################################################
# whatbot/Command/API.pm
###########################################################################
# DEFAULT: API
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::API;
use Moose;
BEGIN {
	extends 'whatbot::Command';
	with    'whatbot::Command::Role::Web';
}

use namespace::autoclean;

has 'seen_ids' => (
	'is'      => 'ro',
	'isa'     => 'HashRef',
	'default' => sub { {} },
);

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	
	if ( $self->my_config and $self->my_config->{enabled} and $self->my_config->{enabled} eq 'yes' ) {
		$self->web(
			'/api/message',
			\&message
		);
		$self->web(
			'/api/karma',
			\&karma
		);
	}
}

sub message {
	my ( $self, $httpd, $req ) = @_;

	return unless ( $self->check_access($req) );

	if ( $req->parm('destination') and $req->parm('message') ) {
		if ( my $id = $req->parm('message_id') ) {
			if ( $self->seen_ids->{$id} ) {
				return _create_content('{"error":"Message ID already used"}');
			}
			$self->seen_ids->{$id} = 1;
		}
		$self->log->write( '*** Message sent from API');
		$self->send_message(
			$req->parm('destination'),
			whatbot::Message->new({
				'to'             => '',
				'from'           => '',
				'content'        => $req->parm('message'),
				'invisible'      => 1,
			}),
		);
		return _create_content('{"status":"ok"}');
	}
	
	return _create_content('{"error":"Missing destination or message"}');
}

sub karma {
	my ( $self, $httpd, $req ) = @_;

	return unless ( $self->check_access($req) );

	if ( $req->parm('subject') and $req->parm('set') and $req->parm('from') ) {
		my $subject = $req->parm('subject');
		my $set = $req->parm('set');
		my $from = $req->parm('from');
		if ( my $id = $req->parm('message_id') ) {
			if ( $self->seen_ids->{$id} ) {
				return _create_content('{"error":"Message ID already used"}');
			}
			$self->seen_ids->{$id} = 1;
		}
		if ( $set !~ /^(up|down)$/ ) {
			return _create_content('{"error":"set parameter must be up or down"}');
		}

		$self->database->connect();
		if ( $set eq 'up' ) {
			$self->model('karma')->increment( $subject, $from );
		} else {
			$self->model('karma')->decrement( $subject, $from );
		}
		$self->log->write( '*** Karma set from API: ' . $subject . ' set ' . $set );

		return _create_content('{"status":"ok"}');
	}
	return _create_content('{"error":"Missing subject, from, or set"}');
}

sub check_access {
	my ( $self, $req ) = @_;

	return unless ( $self->my_config and $self->my_config->{enabled} and $self->my_config->{enabled} eq 'yes' );
	if ( $self->my_config->{limit_ip} ) {
		return unless ( $req->client_host eq $self->my_config->{limit_ip} );
	}
	if ( $self->my_config->{token} ) {
		return unless ( $req->parm('token') eq $self->my_config->{token} );
	}

	return 1;
}

sub _create_content {
	my ($content) = @_;

	return {
		'content' => [ 'application/json', $content ],
	};
}

__PACKAGE__->meta->make_immutable();

1;

