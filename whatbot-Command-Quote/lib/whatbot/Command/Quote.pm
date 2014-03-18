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
	with    'whatbot::Command::Role::BootstrapTemplate';
}

use HTML::Entities;
use whatbot::Helper::Bootstrap::Link;
use namespace::autoclean;

our $VERSION = '0.1';

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);

	whatbot::Helper::Bootstrap->add_application( 'Quote', '/quote' );
	$self->add_menu_item( whatbot::Helper::Bootstrap::Link->new({
		'title' => 'Random Quote',
		'href'  => '/quote/view?id=random',
	}) );

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

sub add_quote : GlobalRegEx('^quote (.*?)[,\:]? "(.*?)"\s*$') {
	my ( $self, $message, $captures ) = @_;
	
	my $quoted = $captures->[0];
	my $content = $captures->[1];
	my $quote = $self->model('Quote')->create({
		'user'    => $message->from,
		'quoted'  => $quoted,
		'content' => encode_entities($content),
	});
	if ($quote) {
		return 'Quote added to quoteboard. ' . ( $self->web_url ? $self->web_url . '/quote' : 'No URL available.' );
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

sub _quote_list_tt2 {
	my $string = q{
<style type="text/css">
	div.quote-body {
		margin-bottom: 18px;
	}
</style>
[% USE date(format='%Y-%m-%d at %H:%M:%S %Z') %]
[% IF success %]
		<div class="bg-success">
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
						<form method="post" role="form">
						<fieldset class="form-inline">
							<h2>Quote Info</h2>
							<div class="form-group">
								<input type="text" class="form-control" name="nickname" placeholder="Submitted By">
							</div>
							<div class="form-group">
								<input type="text" class="form-control" name="quoted" placeholder="Nickname to Quote">
							</div>
						</fieldset>
						<fieldset>
							<h2>Quote Text</h2>
							<div class="form-group">
								<div class="col-xs-6">
									<textarea rows="8" class="form-control" name="content" class="input-xxlarge"></textarea>
								</div>
							</div>
						</fieldset>
						<fieldset>
							<div class="form-group">
								<div class="col-xs-6">
									<button type="submit" class="btn btn-primary">Quote</button>
								</div>
							</div>
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
};
	return \$string;
}

sub _quote_single_tt2 {
	my $string = q{
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
};
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
