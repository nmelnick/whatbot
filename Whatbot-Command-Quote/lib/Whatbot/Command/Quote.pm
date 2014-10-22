###########################################################################
# Whatbot/Command/Quote.pm
###########################################################################
# DEFAULT: Quote
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Quote;
use Moose;
BEGIN {
	extends 'Whatbot::Command';
	with    'Whatbot::Command::Role::Web',
	        'Whatbot::Command::Role::BootstrapTemplate';
}

use HTML::Entities;
use Whatbot::Helper::Bootstrap::Link;
use Try::Tiny;
use namespace::autoclean;

our $VERSION = '0.1';

has 'random_enabled' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'random_start' => ( is => 'rw', isa => 'Int' );
has 'random_end' => ( is => 'rw', isa => 'Int' );
has 'random_days' => ( is => 'rw', isa => 'ArrayRef' );
has 'random_minimum' => ( is => 'rw', isa => 'Int', default => 3600 );
has 'random_maximum' => ( is => 'rw', isa => 'Int', default => 28800 );
has 'random_channel' => ( is => 'rw', isa => 'Str' );

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);

	# Init random quote, if requested
	if ( my $rq = $self->my_config->{random_quote} ) {
		my $start = $rq->{start};
		my $end = $rq->{end};
		my $days = $rq->{days};
		my $channel = $rq->{channel};
		if ( not $days or ref($days) ne 'ARRAY' ) {
			$days = [ 0, 1, 2, 3, 4, 5, 6 ];
		}
		if ( $start and $end and $channel and $start =~ /^\d\d\:\d\d$/ and $end =~ /^\d\d\:\d\d$/ ) {
			$start =~ s/\://;
			$start = '1' . $start;
			$end =~ s/\://;
			$end = '1' . $end;
			$self->random_start($start);
			$self->random_end($end);
			$self->random_days($days);
			$self->random_channel($channel);
			$self->random_minimum( $rq->{minimum_time} ) if ( $rq->{minimum_time} );
			$self->random_maximum( $rq->{maximum_time} ) if ( $rq->{maximum_time} );
			$self->log->write('Random quote enabled.');
			$self->_check_queue_quote();
		} else {
			$self->log->write('start or end not in the format HH:MM, or no channel');
		}
	}

	# Init Web
	Whatbot::Helper::Bootstrap->add_application( 'Quote', '/quote' );
	$self->add_menu_item( Whatbot::Helper::Bootstrap::Link->new({
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
	my $quote = try {
		$self->model('Quote')->create({
			'user'    => $message->from,
			'quoted'  => $quoted,
			'content' => encode_entities($content),
		});
	} catch {
		if ( ref($_) eq 'Exception::QuoteExists' ) {
			return 'Sorry, this was already quoted by ' . $_->{user} . '.';
		}
		warn $_;
		return 'Could not create quote, not sure why.';
	};
	if ( ref($quote) ) {
		return 'Quote added to quoteboard. ' . ( $self->web_url ? $self->web_url . '/quote' : 'No URL available.' );
	} elsif ($quote) {
		return $quote;
	}
	return 'Could not create quote.';
}

sub get_quote_by_id : GlobalRegEx('^quote (\d+)$') {
	my ( $self, $message, $captures ) = @_;
	
	my $quote = $self->model('Quote')->find( $captures->[0] );
	if ($quote) {
		return sprintf( '<%s> %s', $quote->quoted, decode_entities( $quote->content ) );
	}
	return 'Could not find quote #' . $captures->[0] . '.';
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

	my $paste = try {
		$self->model('Quote')->create({
			'user'    => $req->parm('nickname'),
			'quoted'  => $req->parm('quoted'),
			'content' => encode_entities( $req->parm('content') ),
		});
	} catch {
		if ( ref($_) eq 'Exception::QuoteExists' ) {
			return 'Sorry, this was already quoted by ' . $_->{user} . '.';
		}
		warn $_;
		return 'Could not create quote, not sure why.';
	};
	if ( ref($paste) ) {
		$state->{'success'} = 1;
	} elsif ($paste) {
		$state->{'error'} = $paste;
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

sub dispatch_random_quote {
	my ($self) = @_;

	$self->_check_queue_quote();

	my $try_count = 0;
	my $quote = $self->model('Quote')->get_random();
	return unless ($quote);
	while ( $quote->content =~ /[\r\n]/ and $try_count < 30 ) {
		$quote = $self->model('Quote')->get_random();
		$try_count++;
	}
	return unless ($quote);

	$self->send_message(
		$self->random_channel,
		Whatbot::Message->new({
	    	'from'      => 'me',
	    	'to'        => 'public',
	    	'content'   => decode_entities( $quote->content ),
	    	'invisible' => 1,
		})
	);
	return;
}

sub _check_queue_quote {
	my ( $self ) = @_;

	my ( $seconds, $minutes, $hours, $day, $month, $year, $weekday ) = localtime(time);
	my $current_time = sprintf( '1%02d%02d', $hours, $minutes );

	# If time >= start and <= end based on our crappy conversion
	if (
		$current_time >= $self->random_start
		and $current_time <= $self->random_end
		and ( grep { $_ == $weekday } @{$self->random_days} )
	) {
		my $time = $self->_calculate_random_time();
		$self->timer->remove_where_arg( 0, $self );
		$self->timer->enqueue(
			$time,
			\&dispatch_random_quote,
			$self,
		);
	}

	return;
}

sub _calculate_random_time {
	my ($self) = @_;
	return ( $self->random_minimum + int( rand( $self->random_maximum - $self->random_minimum ) ) );
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
							<br>
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

Whatbot::Command::Quote - Provide a web-based quote board

=head1 SYNOPSIS

Config:

"quote" : {
	"random_quote" : {
	   "start" : "10:00",
	   "end" : "23:00",
	   "days" : [ 1, 2, 3, 4, 5 ],
	   "minimum_time" : 1,
	   "maximum_time" : 60,
	   "channel" : "#tesing"
	}
}

=head1 DESCRIPTION

Whatbot::Command::Quote provides a web based quote board, if web access is
enabled in whatbot. A user can add quotes from a web page, or from within a
chat room.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
