###########################################################################
# whatbot/Store/SQLite.pm
###########################################################################
# SQLite Storage
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Store::SQLite;
use Moose;
extends 'whatbot::Store::DBI';

before 'connect' => sub {
	my ($self) = @_;
	$self->connectArray([
		"DBI:SQLite:dbname=" . $self->config->store->{database},
		"",
		""
	]);
};

1;