###########################################################################
# whatbot/Controller.pm
###########################################################################
# Handles incoming messages and where they go
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Controller;
use Moose;
extends 'whatbot::Component';
use whatbot::Message;

has 'Commands' => (
	is	=> 'rw',
	isa	=> 'ArrayRef'
);
has 'skipExtensions' => (
	is	=> 'rw',
	isa	=> 'Int'
);

sub BUILD {
	my ($self) = @_;
	
	$self->buildCommandArray();
}

sub buildCommandArray {
	my ($self) = @_;
	
	my @commands;	# Ordered list of commands
	my %commandMap;	# Maps command priority
	my $commandNamespace = "whatbot::Command";
	
	my $rootDir = $INC{'whatbot/Controller.pm'};
	$rootDir =~ s/Controller\.pm/Command/;
	opendir(EXT, $rootDir);
	while (my $name = readdir(EXT)) {
		next unless ($name =~ /^[A-z0-9]+\.pm$/);
		my $commandPath = $rootDir . "/" . $name;
		$name =~ s/\.pm//;
		my $className = "whatbot::Command::$name";
		eval "require $className";
		if ($@) {
			$self->log->write("ERROR: " . $className . " failed to load: " . $@);
			
		} else {
			if ($className->can('register') and $className->can('parseMessage')) {
				# Instantiate
				my $newCommand = $className->new(
					baseComponent	=> $self->parent->baseComponent
				);
				$newCommand->controller($self);
				
				unless (lc($newCommand->commandPriority) eq 'extension' and $self->skipExtensions) {
					# Send configuration if one exists
					if (defined $self->config->commands->{lc($name)}) {
						$newCommand->{myConfig} = $self->config->commands->{lc($name)};
					}
				
					# Add to map hash
					$commandMap{$className} = $newCommand;
				
					$self->log->write("-> " . ref($newCommand) . " loaded.");
				}
				
			} else {
				$self->log->write("ERROR: " . $className . " failed to load due to missing methods");
			}
		}
	}
	
	# Sort Primary, Core, Extension
	foreach my $priority (qw/primary core extension/) {
		foreach my $command (keys %commandMap) {
			if (lc($commandMap{$command}->commandPriority) eq $priority) {
				push(@commands, $commandMap{$command});
				delete($commandMap{$command});
			}
		}
	}
	
	if (scalar(keys %commandMap) > 0) {
		$self->log->write("ERROR: The following command module(s) did not have a valid priority, and were deactivated:");
		foreach my $command (values %commandMap) {
			$self->log->write(" * " . ref($command));
		}
	}
	%commandMap = ();
	$self->Commands(\@commands);
}

sub handle {
	my ($self, $messageObj, $me) = @_;
	
	foreach my $command (@{$self->Commands}) {
		my $listenFor = $command->listenFor;
		$listenFor = [ $listenFor ] unless (ref($command->listenFor) eq 'ARRAY');
		my $index = 0;
		foreach my $listen (@$listenFor) {
			if (my (@matches) = $messageObj->content =~ $listen or $listen eq '') {
				my $result;
				eval {
					$result = $command->parseMessage($messageObj, $index, @matches);
				};
				if ($@) {
					$self->log->write("ERROR: Failure in " . ref($command) . ": " . $@);
					my $message = new whatbot::Message(
						from			=> '',
						to				=> ($messageObj->isPrivate == 0 ? 'public' : $messageObj->from),
						content			=> ref($command) . " completely failed at that last remark.",
						timestamp		=> time,
						baseComponent	=> $self->parent->baseComponent
					);
					return $message;
					
				} elsif (defined $result) {
					last if ($result eq 'lastRun');
					
					$self->log->write("%%% Message handled by " . ref($command)) unless (defined $self->config->io->[0]->{silent});
					return $result if (ref($result) eq 'whatbot::Message');
					my $message = new whatbot::Message(
						from			=> '',
						to				=> ($messageObj->to eq 'public' ? 'public' : $messageObj->from),
						content			=> $result,
						timestamp		=> time,
						baseComponent	=> $self->parent->baseComponent
					);
					return $message;
				}
				
			}
			$index++;
		}
	}
	
	return undef;
}

1;