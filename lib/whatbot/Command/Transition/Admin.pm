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
use Data::Dumper;

sub register {
	my ($self) = @_;
	
	$self->command_priority("Primary");
	$self->listen_for(qr/^!/);
	$self->require_direct(0);
}

sub parse_message {
	my ($self, $messageRef) = @_;

	return undef unless (defined $self->my_config and $messageRef->from eq $self->my_config->{user});
	
	my ($command, @args) = split(/ /, $messageRef->content);
	$command =~ s/^!+//;

    my $result;
	if ($command eq 'refreshCommands') {
		$result = $self->refreshCommands(@args);
	} elsif ($command eq 'version') {
		$result = $self->version(@args);
	} elsif ($command eq 'rehash') {
		$result = $self->rehash(@args);
	} elsif ($command eq 'svnup') {
		$result = $self->svnup(@args);
	} elsif ($command eq 'retrieve') {
		$result = $self->retrieve(@args);
	} elsif ($command eq 'dumpCommands') {
		$result = $self->dumpCommands(@args);
	}

	return $result if (defined $result);
    return undef;
}

sub refreshCommands {
	my ($self) = @_;
	
	$self->controller->build_command_map();
	return "Rebuilt command set: " . scalar(@{$self->controller->Commands}) . " commands loaded.";
}

sub dumpCommands {
	my ($self) = @_;
	
	my %commands;
	my $listeners = 0;
	foreach my $command (@{$self->controller->Commands}) {
	    $commands{ref($command)} = [] unless ( defined $commands{ref($command)} );
		my $listen_for = $command->listen_for;
		$listen_for = [ $listen_for ] unless (ref($command->listen_for) eq 'ARRAY');
		my $index = 0;
		foreach my $listen (@$listen_for) {
		    $listeners++;
		    push( @{$commands{ref($command)}}, $listen );
		}
	}
	warn Dumper(%commands);
	
	return "Recording " . $listeners .  " listening activities. Details at console.";
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
