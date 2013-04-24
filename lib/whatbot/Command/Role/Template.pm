###########################################################################
# whatbot/Command/Role/Template.pm
###########################################################################
# Provides Template Toolkit to a Command
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Role::Template;
use Moose::Role;
use Template;
use namespace::autoclean;

has 'template' => (
	'is'         => 'ro',
	'lazy_build' => 1,
);

sub _build_template {
	my ($self) = @_;
	return Template->new({}) or die "$Template::ERROR\n";
}

1;

