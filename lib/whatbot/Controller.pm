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
use Class::Inspector;

has 'command'            => ( is => 'rw', isa => 'HashRef' );
has 'command_name'       => ( is => 'rw', isa => 'HashRef' );
has 'command_short_name' => ( is => 'rw', isa => 'HashRef' );
has 'skip_extensions'    => ( is => 'rw', isa => 'Int' );

sub BUILD {
	my ( $self ) = @_;
	
	$self->build_command_map();
}

sub build_command_map {
	my ( $self ) = @_;
	
	my %command;	    # Ordered list of commands
	my %command_name;   # Maps command names to commands
	my %command_short_name;
	my $command_namespace = 'whatbot::Command';
	my $root_dir = $INC{'whatbot/Controller.pm'};
	$root_dir =~ s/Controller\.pm/Command/;
	
	opendir(COMMAND_DIR, $root_dir);
	while (my $name = readdir(COMMAND_DIR)) {
		next unless ($name =~ /^[A-z0-9]+\.pm$/);
		
		my $commandPath = $root_dir . '/' . $name;
		$name =~ s/\.pm//;
		my $class_name = 'whatbot::Command::' . $name;
		eval "require $class_name";
		if ($@) {
			$self->log->write('ERROR: ' . $class_name . ' failed to load: ' . $@);
		} else {
			unless ( $class_name->can('register') ) {
				$self->log->write('ERROR: ' . $class_name . ' failed to load due to missing methods');
			} else {
			    my @run_paths;
			    my $command_root = $class_name;
			    $command_root =~ s/$command_namespace\:\://;
			    $command_root = lc($command_root);
			    
				# Instantiate
				my $new_command = $class_name->new(
					'base_component' => $self->parent->base_component
				);
				$new_command->controller($self);
				
				# Determine runpaths
				foreach my $function ( @{Class::Inspector->functions($class_name)} ) {
				    my $full_function = $class_name . '::' . $function;
				    my $coderef = \&$full_function;
				    
				    if ( my $attributes = $new_command->FETCH_CODE_ATTRIBUTES($coderef) ) {
				        foreach my $attribute ( @{$attributes} ) {
				            my ( $command, $arguments ) = split( /\s*\(/, $attribute, 2 );
				            if ( $command eq 'Command' ) {
				                my $register = '^' . $command_root . ' *' . $function;
				                if ( $command_name{$register} ) {
				                    $self->error_override( $class_name, $register )
			                    } else {
    				                push(
    				                    @run_paths,
    				                    {
    				                        'match'     => $register,
    				                        'function'  => $function
    				                    }
    				                );
			                    }
				                

				            } elsif ( $command eq 'CommandRegEx' ) {
				                $arguments =~ s/\)$//;
				                unless ( $arguments =~ /^'.*?'$/ ) {
				                    $self->error_regex( $class_name, $function, $arguments );
				                } else {
    				                $arguments =~ s/^'(.*?)'$/$1/;
    				                my $register = '^' . $command_root . ' *' . $arguments;
    				                if ( $command_name{$register} ) {
    				                    $self->error_override( $class_name, $register )
    			                    } else {
        				                push(
        				                    @run_paths,
        				                    {
        				                        'match'     => $register,
        				                        'function'  => $function
        				                    }
        				                );
    			                    }
		                        }
				                    
				            } elsif ( $command eq 'GlobalRegEx' ) {
				                $arguments =~ s/\)$//;
				                unless ( $arguments =~ /^'.*?'$/ ) {
				                    $self->error_regex( $class_name, $function, $arguments );
				                } else {
				                    $arguments =~ s/^'(.*?)'$/$1/;
    				                if ( $command_name{$arguments} ) {
    				                    $self->error_override( $class_name, $arguments )
    			                    } else {
        				                push(
        				                    @run_paths,
        				                    {
        				                        'match'     => $arguments,
        				                        'function'  => $function
        				                    }
        				                );
    			                    }
				                }
				                
				            } elsif ( $command eq 'Monitor' ) {
				                push(
				                    @run_paths,
				                    {
				                        'match'     => '',
				                        'function'  => $function
				                    }
				                );
				                
				            } else {
				                $self->log->write('ERROR: ' . $class_name . ': Invalid attribute "' . $command . '" on method "' . $function . '", ignoring.');
				            }
				        }
				    }
				}
				
				$new_command->command_priority('Extension') unless ( $new_command->command_priority );
				unless ( lc($new_command->command_priority) eq 'extension' and $self->skip_extensions ) {
					# Send configuration if one exists
					if (defined $self->config->commands->{lc($name)}) {
						$new_command->{'my_config'} = $self->config->commands->{lc($name)};
					}
				
					# Add to command structure and name to command map
					$command{ lc($new_command->command_priority) }->{$class_name} = \@run_paths;
					$command_name{$class_name} = $new_command;
					$command_short_name{$command_root} = $new_command;
				
					$self->log->write('-> ' . ref($new_command) . ' loaded.');
				}
			}
		}
	}
	close(COMMAND_DIR);
	
    $self->command(\%command);
    $self->command_name(\%command_name);
    $self->command_short_name(\%command_short_name);
}

sub handle {
	my ( $self, $message, $me ) = @_;
	
	my @messages;
	foreach my $priority ( qw( primary core extension ) ) {
    	foreach my $command_name ( keys %{ $self->command->{$priority} } ) {
    	    my $command = $self->command_name->{$command_name};
    	    next if ( $command->require_direct and !$message->is_direct );
    	    
    		foreach my $run_path ( @{ $self->command->{$priority}->{$command_name} } ) {
    		    my $listen = $run_path->{'match'};
    		    my $function = $run_path->{'function'};
    		    
    			if ( $listen eq '' or my (@matches) = $message->content =~ /$listen/i ) {
    				my $result;
    				eval {
    					$result = $command->$function( $message, \@matches );
    				};
    				if ($@) {
    					$self->log->write( 'ERROR: Failure in ' . $command_name . ': ' . $@ );
    					my $return_message = new whatbot::Message(
    						'from'			 => '',
    						'to'			 => ($message->is_private == 0 ? 'public' : $message->from),
    						'content'		 => $command_name . ' completely failed at that last remark.',
    						'timestamp'		 => time,
    						'base_component' => $self->parent->base_component
    					);
    					push( @messages, $return_message);
					
    				} elsif ( defined $result ) {
    					last if ( $result eq 'last_run' );
					
    					$self->log->write('%%% Message handled by ' . $command_name)
    					    unless ( defined $self->config->io->[0]->{'silent'} );
    					push( @messages, $result ) if ( ref($result) eq 'whatbot::Message' );
    					my $message = new whatbot::Message(
    						from			=> '',
    						to				=> ($message->to eq 'public' ? 'public' : $message->from),
    						content			=> $result,
    						timestamp		=> time,
    						base_component	=> $self->parent->base_component
    					);
    					push( @messages, $message );
    				}
				
    			}
    		}
    	}
    }
	
	return \@messages;
}

sub dump_command_map {
    my ( $self ) = @_;
    
	foreach my $priority ( qw( primary core extension ) ) {
	    my $commands = 0;
	    
	    $self->log->write( uc($priority) . ':' );
	    
    	foreach my $command_name ( keys %{ $self->command->{$priority} } ) {
    		foreach my $run_path ( @{ $self->command->{$priority}->{$command_name} } ) {
    	        $self->log->write( '  /' . $run_path->{'match'} . '/ -> ' . $command_name . '::' . $run_path->{'function'} );
    	        $commands++;
	        }
	    }
	    
	    $self->log->write('  none') unless ($commands);
    }
}

sub error_override {
    my ( $self, $class, $name ) = @_;
    
    $self->log->write( 'ERROR: ' . $class . ': More than one command being registered for "' . $name . '".' )
}

sub error_regex {
    my ( $self, $class, $function, $regex ) = @_;
    
    $self->log->write( 'ERROR: ' . $class . ': Invalid arguments (' . $regex . ') in method "' . $function . '".' )
}

1;