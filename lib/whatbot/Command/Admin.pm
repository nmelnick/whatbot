###########################################################################
# whatbot/Command/Admin.pm
###########################################################################
# DEFAULT: Administrative functions
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Admin;
use Moose;
BEGIN { extends 'whatbot::Command'; }

use Cwd qw(realpath);
use Data::Dumper;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Primary');
	$self->require_direct(0);
}

sub refresh : Command {
	my ( $self, $message ) = @_;
	
	return undef unless ( defined $self->my_config and $message->from eq $self->my_config->{'user'} );
	
	$self->controller->build_command_map();
	return 'Rebuilt command set: ' . scalar(@{$self->controller->command_name}) . ' commands loaded.';
}

sub version : Command {
	my ( $self, $message ) = @_;
	
	return undef unless ( defined $self->my_config and $message->from eq $self->my_config->{'user'} );
	
	my $verString = 'whatbot ' . $self->parent->version;
	# Get basedir
	my $basedir = realpath($0);
	my $appname = $0;
	$appname =~ s/.*?\///g;
	$basedir =~ s/\/$appname$//;
	$basedir =~ s/\/bin$//;
	if ( -e $basedir . '/.svn' ) {
		my $inf = `svn info $basedir`;
		if ( $inf =~ /Revision:\s+(\d+)/ ) {
			$verString .= ' (svn r' . $1 . ')';
		}
	} else {
		warn $basedir;
	}
	
	return $verString;
}

sub rehash : Command {
	my ( $self, $message ) = @_;
	
	return undef unless ( defined $self->my_config and $message->from eq $self->my_config->{'user'} );
	
	system( $ENV{_} . ' ' . join( ' ', @ARGV ) . ' &' );
	exit(1);
}

sub svnup : Command {
	my ( $self, $message ) = @_;
	
	return undef unless ( defined $self->my_config and $message->from eq $self->my_config->{'user'} );
	
	# Get basedir
	my $basedir = realpath($0);
	my $appname = $0;
	$appname =~ s/.*?\///g;
	$basedir =~ s/\/$appname$//;
	$basedir =~ s/\/bin$//;
	if (-e $basedir . '/.svn') {
		my $inf = `svn up $basedir`;
		$inf = `svn info $basedir`;
		if ($inf =~ /Revision:\s+(\d+)/) {
			return 'Now at svn r' . $1 . '.';
		}
	} else {
		warn $basedir;
		return 'This is not a SVN install.';
	}
	return undef;
}

sub retrieve : Command {
	my ( $self, $message ) = @_;
	
	return undef unless ( defined $self->my_config and $message->from eq $self->my_config->{'user'} );
	
	my $content = $message->content;
	$content =~ s/^admin *retrieve *//;
	my ( $table, $columns, @where ) = split( //, $content );
	
	my %where_hash;
	foreach my $w (@where) {
		my ($k, $v) = split(/=/, $w);
		$where_hash{$k} = $v;
	}
	my ($result) = @{ $self->store->retrieve($table, [split(/\|/, $columns)], \%where_hash) };
	my $response;
	foreach my $key (keys %$result) {
		$response .= $key . ' => "' . $result->{$key} . '" ';
	}
	return $response;
}

1;
