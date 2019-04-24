###########################################################################
# Whatbot/Command/Role/Template.pm
###########################################################################
# Provides Template Toolkit to a Command
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package Whatbot::Command::Role::Template;
use Moose::Role;
use Template;
use namespace::autoclean;

has 'template' => (
	'is'         => 'ro',
	'lazy_build' => 1,
);

sub _build_template {
	my ($self) = @_;
	my $template = Template->new({});
	die "$Template::ERROR\n" unless ($template);
	return $template;
}

sub render {
	my ( $self, $req, $tt2, $params ) = @_;

	my $out;
	$self->template->process( $tt2, $params, \$out );
	$req->respond({
		'content' => [ 'text/html', $out ],
	});
}

1;

