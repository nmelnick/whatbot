###########################################################################
# whatbot/Command/Admin.pm
###########################################################################
# DEFAULT: Administrative functions
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Admin;
use Moose;
extends 'whatbot::Command';
use Cwd qw(realpath);

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Primary");
	$self->listenFor(qr/^!/);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;
	
	return undef unless ($messageRef->from eq $self->myConfig->{user});
	my ($command, @args) = split(/ /, $messageRef->content);
	$command =~ s/^!//;
	if ($command eq 'refreshCommands') {
		return $self->refreshCommands(@args);
	} elsif ($command eq 'version') {
		return $self->version(@args);
	} elsif ($command eq 'rehash') {
		return $self->rehash(@args);
	} elsif ($command eq 'svnup') {
		return $self->svnup(@args);
	} elsif ($command eq 'retrieve') {
		return $self->retrieve(@args);
	}
	return undef;
}

sub refreshCommands {
	my ($self) = @_;
	
	$self->controller->buildCommandArray();
	return "Rebuilt command set: " . scalar(@{$self->controller->Commands}) . " commands loaded.";
}

sub version {
	my ($self) = @_;
	
	my $verString = "whatbot " . $self->parent->version;
	# Get basedir
	my $basedir = realpath($0);
	my $appname = $0;
	$appname =~ s/.*?\///g;
	$basedir =~ s/\/$appname$//;
	$basedir =~ s/\/bin$//;
	if (-e $basedir . "/.svn") {
		my $inf = `svn info $basedir`;
		if ($inf =~ /Revision:\s+(\d+)/) {
			$verString .= " (svn r" . $1 . ")";
		}
	} else {
		warn $basedir;
	}
	
	return $verString;
}

sub rehash {
	my ($self) = @_;
	
	system($ENV{_} . " " . join(" ", @ARGV) . " &");
	exit(1);
}

sub svnup {
	my ($self) = @_;
	
	# Get basedir
	my $basedir = realpath($0);
	my $appname = $0;
	$appname =~ s/.*?\///g;
	$basedir =~ s/\/$appname$//;
	$basedir =~ s/\/bin$//;
	if (-e $basedir . "/.svn") {
		my $inf = `svn up $basedir`;
		$inf = `svn info $basedir`;
		if ($inf =~ /Revision:\s+(\d+)/) {
			return "Now at svn r" . $1 . ".";
		}
	} else {
		warn $basedir;
		return "This is not a SVN install.";
	}
	return undef;
}

sub retrieve {
	my ($self, $table, $columns, @where) = @_;
	
	my %whereHash;
	foreach my $w (@where) {
		my ($k, $v) = split(/=/, $w);
		$whereHash{$k} = $v;
	}
	my ($result) = @{$self->store->retrieve($table, [split(/\|/, $columns)], \%whereHash)};
	my $response;
	foreach my $k (keys %$result) {
		$response .= "$k => \"" . $result->{$k} . "\" ";
	}
	return $response;
}

1;