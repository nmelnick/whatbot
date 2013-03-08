###########################################################################
# whatbot/Command/API.pm
###########################################################################
# DEFAULT: API
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::API;
use Moose;
BEGIN { extends 'whatbot::Command'; }

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
	my ( $self, $cgi ) = @_;

	return unless ( $self->check_access($cgi) );

	print "Content-type: application/json\r\n\r\n";
	if ( $cgi->param('destination') and $cgi->param('message') ) {
		if ( my $id = $cgi->param('message_id') ) {
			if ( $self->seen_ids->{$id} ) {
				print '{"error":"Message ID already used"}';
				return;
			}
			$self->seen_ids->{$id} = 1;
		}
		$self->log->write( '*** Message sent from API');
		$self->send_message(
			$cgi->param('destination'),
			whatbot::Message->new({
				'to'             => '',
				'from'           => '',
				'content'        => $cgi->param('message'),
				'base_component' => $self->parent->base_component,
				'invisible'      => 1,
			}),
		);
		print '{"status":"ok"}';
	} else {
		print '{"error":"Missing destination or message"}';
	}

	return;
}

sub karma {
	my ( $self, $cgi ) = @_;

	return unless ( $self->check_access($cgi) );

	print "Content-type: application/json\r\n\r\n";
	if ( $cgi->param('subject') and $cgi->param('set') and $cgi->param('from') ) {
		my $subject = $cgi->param('subject');
		my $set = $cgi->param('set');
		my $from = $cgi->param('from');
		if ( my $id = $cgi->param('message_id') ) {
			if ( $self->seen_ids->{$id} ) {
				print '{"error":"Message ID already used"}';
				return;
			}
			$self->seen_ids->{$id} = 1;
		}
		if ( $set !~ /^(up|down)$/ ) {
			print '{"error":"set parameter must be up or down"}';
			return;
		}

		$self->database->connect();
		if ( $set eq 'up' ) {
			$self->model('karma')->increment( $subject, $from );
		} else {
			$self->model('karma')->decrement( $subject, $from );
		}
		$self->log->write( '*** Karma set from API: ' . $subject . ' set ' . $set );

		print '{"status":"ok"}';
	} else {
		print '{"error":"Missing subject, from, or set"}';
	}

	return;
}

sub check_access {
	my ( $self, $cgi ) = @_;

	return unless ( $self->my_config and $self->my_config->{enabled} and $self->my_config->{enabled} eq 'yes' );
	if ( $self->my_config->{limit_ip} ) {
		return unless ( $cgi->remote_addr eq $self->my_config->{limit_ip} );
	}
	if ( $self->my_config->{token} ) {
		return unless ( $cgi->param('token') eq $self->my_config->{token} );
	}

	return 1;
}

__PACKAGE__->meta->make_immutable();

1;

