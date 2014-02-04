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
	with 'whatbot::Command::Role::Template';
}

use HTML::Entities;
use namespace::autoclean;

our $VERSION = '0.1';

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	
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
		'channels' => [ sort @channels ],
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
		'title' => 'Viewing paste ' . $id,
		'paste' => $self->model('Paste')->find($id),
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

sub _header {
	return q{
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>[% title OR 'whatbot Paste' %]</title>
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<style type="text/css">
		body {
			padding-top: 60px;
			font-family: Candara, sans-serif;
			font-size: 14px;
		}
		div.error {
			padding: 14px;
			background-color: #fee;
			border: 1px solid #f00;
			margin-bottom: 18px;
		}
		div.success {
			padding: 14px;
			background-color: #efe;
			border: 1px solid #0f0;
			margin-bottom: 18px;
		}
		div.pastedata {
			margin-bottom: 18px;
		}
		div.code {
			padding: 14px;
		}
	</style>
	<link href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.min.css" rel="stylesheet">
</head>
<body>
	<div class="navbar navbar-inverse navbar-fixed-top">
		<div class="navbar-inner">
		<div class="container">
			<button type="button" class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
			<span class="icon-bar"></span>
			<span class="icon-bar"></span>
			<span class="icon-bar"></span>
			</button>
			<a class="brand" href="/paste">whatbot Paste</a>
			<div class="nav-collapse collapse">
			<ul class="nav"></ul>
			</div>
		</div>
		</div>
	</div>

	<div class="container">
[% IF error %]
		<div class="error">
			[% error %]
		</div>
[% END %]
};
}

sub _footer {
	return q{
	</div>
	<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
</body>
</html>
};
}

sub _paste_form_tt2 {
	my $string = _header() . q{
[% IF url %]
		<div class="success">
			Paste created successfully. You may view it <a href="[% url %]">here</a>.
		</div>
[% END %]
		<p>
			This is the whatbot Paste service. Please enter your IRC nickname,
			the channel you'd like to broadcast to (if any), and the contents
			of your paste.
		</p>
		<form method="POST">
		<fieldset class="form-inline">
			<legend>Paste Information</legend>
			<input type="text" name="nickname" placeholder="Your Nickname">
			<select name="channel">
				<option name="">&lt;no channel&gt;</option>
[% FOREACH channel IN channels %]
				<option name="[% channel %]">[% channel %]</option>
[% END %]
			</select>
		</fieldset>
		<fieldset>
			<legend>Content</legend>
			<input type="text" name="summary" class="input-xxlarge" placeholder="Summary (optional)">
			<br />
			<textarea rows="8" name="content" class="input-xxlarge"></textarea>
		</fieldset>
		<fieldset>
			<button type="submit" class="btn">Paste</button>
		</fieldset>
		</form>
} . _footer();
	return \$string;
}

sub _paste_view_tt2 {
	my $string = _header() . q{
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
} . _footer();
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
