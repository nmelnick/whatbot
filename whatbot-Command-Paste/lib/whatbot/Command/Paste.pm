###########################################################################
# whatbot/Command/Paste.pm
###########################################################################
# DEFAULT: Paste
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Paste;
use Moose;
BEGIN {
	extends 'whatbot::Command';
	with 'whatbot::Command::Role::BootstrapTemplate';
}

use HTML::Entities;
use namespace::autoclean;

our $VERSION = '0.1';

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);

	whatbot::Helper::Bootstrap->add_application( 'Paste', '/paste' );
	
	$self->web(
		'/paste',
		\&paste_form
	);
	$self->web(
		'/paste/view',
		\&paste_view
	);
}

sub help : Command {
    my ( $self ) = @_;
    
    return [
        'Paste is available through a web browser at '
        . sprintf( '%s/paste', $self->web_url() )
        . '. New pastes will come into the channel if the paster requests it.'
    ];
}

sub paste_form {
	my ( $self, $httpd, $req ) = @_;

	return unless ( $self->check_access($req) );

	my @channels;
	foreach my $io ( values %{ $self->ios } ) {
		next unless ( $io->can('channels') );
		push( @channels, ( map { $_->{'name'} } @{ $io->channels } ) );
	}

	my %state = (
		'page_title' => 'whatbot Paste',
		'channels'   => [ sort @channels ],
	);

	if ( $req->method eq 'POST' ) {
		$self->_submit_form( $req, \%state );
	}

	return $self->render( $req, _paste_form_tt2(), \%state );
}

sub paste_view {
	my ( $self, $httpd, $req ) = @_;

	return unless ( $self->check_access($req) );

	my $id = $req->parm('id');
	return '' unless ($id);

	my %state = (
		'page_title' => 'whatbot Paste',
		'title'      => 'Viewing paste ' . $id,
		'paste'      => $self->model('Paste')->find($id),
	);

	return $self->render( $req, _paste_view_tt2(), \%state );
}

sub _submit_form {
	my ( $self, $req, $state ) = @_;

	unless ( $req->parm('nickname') ) {
		$state->{'error'} = 'Missing nickname.';
		return;
	}

	unless ( $req->parm('content') ) {
		$state->{'error'} = 'Missing content.';
		return;
	}

	my $paste = $self->model('Paste')->create({
		'user'        => $req->parm('nickname'),
		'destination' => ( $req->parm('channel') or undef ),
		'summary'     => ( $req->parm('summary') or 'none' ),
		'content'     => encode_entities( $req->parm('content') ),
	});
	if ($paste) {
		$state->{'url'} = '/paste/view?id=' . $paste->paste_id;

		if ( $paste->destination ) {
			$self->send_message(
				$paste->destination,
				whatbot::Message->new({
					'to'             => '',
					'from'           => '',
					'content'        => sprintf(
						'New paste: "%s", available at %s/paste/view?id=%d',
						$paste->summary,
						$self->web_url,
						$paste->paste_id
					),
					'invisible'      => 1,
				}),
			);
		}
	} else {
		$state->{'error'} = 'Unknown error creating paste.';		
	}
	return;
}

sub check_access {
	my ( $self, $req ) = @_;

	if ( $self->my_config and $self->my_config->{limit_ip} ) {
		return unless ( $req->remote_host eq $self->my_config->{limit_ip} );
	}

	return 1;
}

sub _paste_form_tt2 {
	my $string = q{
[% IF url %]
		<div class="bg-success">
			Paste created successfully. You may view it <a href="[% url %]">here</a>.
		</div>
[% END %]
		<p>
			This is the whatbot Paste service. Please enter your IRC nickname,
			the channel you'd like to broadcast to (if any), and the contents
			of your paste.
		</p>
		<form method="post" role="form">
			<fieldset class="form-inline">
				<h2>Paste Information</h2>
				<div class="form-group">
					<label class="sr-only" for="f-nickname">Your Nickname</label>
					<div class="col-xs-3">
						<input type="text" class="form-control" id="f-nickname" name="nickname" placeholder="Your Nickname">
					</div>
				</div>
				<div class="form-group">
					<label class="sr-only" for="f-channel">Channel</label>
					<div class="col-xs-3">
						<select name="channel" class="form-control" id="f-channel">
							<option name="">&lt;no channel&gt;</option>
[% FOREACH channel IN channels %]
							<option name="[% channel %]">[% channel %]</option>
[% END %]
						</select>
					</div>
				</div>
			</fieldset>
			<fieldset>
				<h2>Content</h2>
				<div class="form-group">
					<div class="col-xs-6">
						<input type="text" class="form-control" name="summary" placeholder="Summary (optional)">
						<br />
						<textarea rows="8" class="form-control" name="content"></textarea>
					</div>
				</div>
			</fieldset>
			<fieldset>
				<div class="form-group">
					<div class="col-xs-6">
						<button type="submit" class="btn btn-primary">Paste</button>
					</div>
				</div>
			</fieldset>
		</form>
};
	return \$string;
}

sub _paste_view_tt2 {
	my $string = q{
<style type="text/css">
	div.pastedata {
		margin-bottom: 18px;
	}
	div.code {
		padding: 14px;
	}
</style>
[% USE date(format='%Y-%m-%d %H:%M:%S %Z') %]
[% IF paste %]
	<div class="pastedata">
		<div>
			<strong>Summary: </strong>
			[% paste.summary %]
		</div>
		<div>
			<strong>Nickname: </strong>
			[% paste.user %]
		</div>
		<div>
			<strong>Timestamp: </strong>
			[% date.format(paste.timestamp) %]
		</div>
	</div>
	<div class="code">
	<pre>[% paste.content %]</pre>
	</div>
[% ELSE %]
	No paste.
[% END %]
};
	return \$string;
}

__PACKAGE__->meta->make_immutable();

1;

=pod

=head1 NAME

whatbot::Command::Paste - A simple web-based pastebot

=head1 DESCRIPTION

whatbot::Command::Paste provides a simple web-based pastebot. Accepts pastes
from anywhere, and optionally notifies a given channel about the paste.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
