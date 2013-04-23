###########################################################################
# whatbot/Command/Paste.pm
###########################################################################
# DEFAULT: Paste
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Paste;
use Moose;
use Template;
BEGIN { extends 'whatbot::Command'; }

use namespace::autoclean;

has 'template' => (
	'is'         => 'ro',
	'lazy_build' => 1,
);

sub _build_template {
	my ($self) = @_;
	return Template->new({}) || die "$Template::ERROR\n";
}

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
	
	if (
		$self->my_config
		and $self->my_config->{enabled}
		and $self->my_config->{enabled} eq 'yes'
	) {
		$self->web(
			'/paste',
			\&paste_form
		);
		$self->web(
			'/paste/view',
			\&paste_view
		);
	}
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
	my ( $self, $cgi ) = @_;

	return unless ( $self->check_access($cgi) );

	my @channels;
	foreach my $io ( values %{ $self->ios } ) {
		next unless ( $io->can('channels') );
		push( @channels, ( map { $_->{'name'} } @{ $io->channels } ) );
	}

	my %state = (
		'channels' => [ sort @channels ],
	);

	print "Content-type: text/html\r\n\r\n";
	if ( $cgi->request_method eq 'POST' ) {
		$self->_submit_form( $cgi, \%state );
	}

	$self->template->process( _paste_form_tt2(), \%state );

	return;
}

sub paste_view {
	my ( $self, $cgi ) = @_;

	return unless ( $self->check_access($cgi) );

	my $id = $cgi->param('id');
	unless ($id) {
		return '';
	}

	my %state = (
		'title' => 'Viewing paste ' . $id,
		'paste' => $self->model('Paste')->find($id),
	);

	$self->template->process( _paste_view_tt2(), \%state );

	return;
}

sub _submit_form {
	my ( $self, $cgi, $state ) = @_;

	unless ( $cgi->param('nickname') ) {
		$state->{'error'} = 'Missing nickname.';
		return;
	}

	unless ( $cgi->param('content') ) {
		$state->{'error'} = 'Missing content.';
		return;
	}

	my $paste = $self->model('Paste')->create({
		'user'        => $cgi->param('nickname'),
		'destination' => ( $cgi->param('channel') or undef ),
		'summary'     => ( $cgi->param('summary') or 'none' ),
		'content'     => $cgi->param('content'),
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
					'base_component' => $self->parent->base_component,
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
	my ( $self, $cgi ) = @_;

	return unless (
		$self->my_config
		and $self->my_config->{enabled}
		and $self->my_config->{enabled} eq 'yes'
	);
	if ( $self->my_config->{limit_ip} ) {
		return unless ( $cgi->remote_addr eq $self->my_config->{limit_ip} );
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
			</label>
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

