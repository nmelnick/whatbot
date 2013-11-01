###########################################################################
# whatbot/Command/Quote.pm
###########################################################################
# DEFAULT: Quote
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Quote;
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
		'/quote',
		\&quote_list
	);
	$self->web(
		'/quote/view',
		\&quote_single
	);
}

sub help : Command {
    my ( $self ) = @_;
    
    return [
        'Quote is available through a web browser at '
        . sprintf( '%s/quote', $self->web_url() )
        . '. You may add a quote by using:',
        'quote <user> "<quote>"',
        'Example: quote AwesomeUser "That was incredible!"'
    ];
}

sub add_quote : GlobalRegEx('^quote (.*) "(.*?)"\s*$') {
	my ( $self, $message, $captures ) = @_;
	
	my $quoted = $captures->[0];
	my $content = $captures->[1];
	my $quote = $self->model('Quote')->create({
		'user'    => $message->from,
		'quoted'  => $quoted,
		'content' => encode_entities($content),
	});
	if ($quote) {
		return 'Quote added to quoteboard. ' . $self->web_url . '/quote';
	}
	return 'Could not create quote.';
}

sub quote_list {
	my ( $self, $httpd, $req ) = @_;

	return unless ( $self->check_access($req) );

	my %state = ();
	if ( $req->method eq 'POST' ) {
		$self->_submit_form( $req, \%state );
	}

	$state{'quotes'} = $self->model('Quote')->search({ '_order_by' => 'timestamp desc' });

	return $self->render( $req, _quote_list_tt2(), \%state );
}

sub quote_single {
	my ( $self, $httpd, $req ) = @_;

	return unless ( $self->check_access($req) );

	my %state = ();
	my $id = $req->parm('id');
	return '' unless ($id);

	if ( $id ne 'random' ) {
		$state{'quote'} = $self->model('Quote')->find($id);
	} else {
		$state{'quote'} = $self->model('Quote')->search_one({
			'_order_by' => $self->database->random(),
			'_limit'    => 1,
		});
	}
	

	return $self->render( $req, _quote_single_tt2(), \%state );
}

sub _submit_form {
	my ( $self, $req, $state ) = @_;

	foreach my $required ( qw( nickname quoted content ) ) {
		unless ( $req->parm($required) ) {
			$state->{'error'} = 'Missing ' . $required . '.';
			return;
		}
	}

	my $paste = $self->model('Quote')->create({
		'user'    => $req->parm('nickname'),
		'quoted'  => $req->parm('quoted'),
		'content' => encode_entities( $req->parm('content') ),
	});
	if ($paste) {
		$state->{'success'} = 1;
	} else {
		$state->{'error'} = 'Unknown error creating quote.';		
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
	<title>[% title OR 'whatbot Quoteboard' %]</title>
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
		div.quote-body {
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
			<a class="brand" href="/quote">whatbot Quoteboard</a>
			<div class="nav-collapse collapse">
			<ul class="nav">
				<li><a href="/quote/view?id=random">Random Quote</a></li>
			</ul>
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
	<script src="http://code.jquery.com/jquery-1.9.1.min.js"></script>
	<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"></script>
</body>
</html>
};
}

sub _quote_list_tt2 {
	my $string = _header() . q{
[% USE date(format='%Y-%m-%d at %H:%M:%S %Z') %]
[% IF success %]
		<div class="success">
			Quote added successfully.
		</div>
[% END %]
		<p>
			This is the whatbot Quoteboard.
		</p>
		<div class="accordion" id="accordion2">
			<div class="accordion-group">
				<div class="accordion-heading">
					<a class="accordion-toggle" data-toggle="collapse" data-parent="#accordion2" href="#collapseOne">
					Add a Quote
					</a>
				</div>
				<div id="collapseOne" class="accordion-body collapse">
					<div class="accordion-inner">
						<form method="post">
						<fieldset class="form-inline">
							<legend>Quote Info</legend>
							<input type="text" name="nickname" placeholder="Submitted By">
							<input type="text" name="quoted" placeholder="Nickname to Quote">
						</fieldset>
						<fieldset>
							<legend>Quote Text</legend>
							<textarea rows="8" name="content" class="input-xxlarge"></textarea>
						</fieldset>
						<fieldset>
							<button type="submit" class="btn">Quote</button>
						</fieldset>
						</form>
					</div>
				</div>
			</div>
		</div>
		<h2>Quotes</h2>
		<div class="quote-list">
[% FOREACH quote IN quotes %]
	<div class="quote-body">
		<blockquote>
			<p>[% quote.content FILTER html_line_break %]</p>
			<small>[% quote.quoted %], on [% date.format(quote.timestamp) %] (<a href="/quote/view?id=[% quote.quote_id %]">[% quote.quote_id %]</a>)</small>
		</blockquote>
	</div>
[% END %]
		</div>
} . _footer();
	return \$string;
}

sub _quote_single_tt2 {
	my $string = _header() . q{
<style type="text/css">
	.big-and-center {
		margin: 40px auto;
		width: 80%;
	}
	.big-and-center .quote-body {
		font-size: 170%;
	}
	.big-and-center .quote-body p {
		font-size: 170%;
		margin-bottom: 20px;
	}
</style>
[% USE date(format='%Y-%m-%d at %H:%M:%S %Z') %]
<div class="big-and-center">
	<div class="quote-body">
		<blockquote>
			<p>[% quote.content FILTER html_line_break %]</p>
			<small>[% quote.quoted %], on [% date.format(quote.timestamp) %] (<a href="/quote/view?id=[% quote.quote_id %]">[% quote.quote_id %]</a>)</small>
		</blockquote>
	</div>
</div>
} . _footer();
	return \$string;
}

__PACKAGE__->meta->make_immutable();

1;

=pod

=head1 NAME

whatbot::Command::Quote - Provide a web-based quote board

=head1 SYNOPSIS

Config:

"quote" : {
	"enabled" : "yes"
}

=head1 DESCRIPTION

whatbot::Command::Quote provides a web based quote board, if web access is
enabled in whatbot. A user can add quotes from a web page, or from within a
chat room.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
