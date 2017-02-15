###########################################################################
# Controller.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Controller - Command processor and dispatcher

=head1 SYNOPSIS

 use Whatbot::Controller;
 
 my $controller = Whatbot::Controller->new();
 $controller->build_command_map();
 
 ...
 
 my $messages = $controller->handle_message( $incoming_message );

=head1 DESCRIPTION

Whatbot::Controller is the master command dispatcher for whatbot. When whatbot
is started, Controller builds the run paths based on the attributes in the
Whatbot::Command namespace. When a message event is fired during runtime,
Controller parses the message and directs the event to each appropriate
command.

=head1 METHODS

=over 4

=cut

class Whatbot::Controller extends Whatbot::Component with Whatbot::Role::Pluggable {
	use Whatbot::Message;
	use Class::Inspector;
	use Class::Load qw(load_class);
	use Devel::StackTrace;

	has 'command'            => ( is => 'rw', isa => 'HashRef' );
	has 'command_name'       => ( is => 'rw', isa => 'HashRef' );
	has 'command_short_name' => ( is => 'rw', isa => 'HashRef' );
	has 'skip_extensions'    => ( is => 'rw', isa => 'Int' );
	has 'search_base'        => ( is => 'ro', default => 'Whatbot::Command' );

	method BUILD (...) {
		$self->build_command_map();
	}

	method build_command_map {
		my %command;	    # Ordered list of commands
		my %command_short_name;
		$self->command_name( {} ); # Maps command names to commands

		my $blacklist = ( $self->config->config_hash->{'blacklist'} or [] );
		my $whitelist = ( $self->config->config_hash->{'whitelist'} or [] );
	
		# Scan Whatbot::Command for loadable plugins
		foreach my $class_name ( $self->plugins ) {
			my @class_split = split( /\:\:/, $class_name );
			my $name = pop(@class_split);

			# Go away unless it's a root module
			next unless ( pop(@class_split) eq 'Command' );

			# Deny or allow according to blacklist/whitelist
			if (@$whitelist) {
				my $allow = 0;
				foreach my $module (@$whitelist) {
					if ( $module eq $name ) {
						$allow++;
						last;
					}
				}
				next unless ($allow);
			}
			if (@$blacklist) {
				my $listed = 0;
				foreach my $module (@$blacklist) {
					if ( $module eq $name ) {
						$listed++;
						last;
					}
					next if ($listed);
				}
			}

			eval {
				load_class($class_name);
			};
			if ($@) {
				$self->log->error( $class_name . ' failed to load: ' . $@ );
			} else {
				unless ( $class_name->can('register') ) {
					$self->log->error( $class_name . ' failed to load due to missing methods' );
				} else {
					my @run_paths;
					my %end_paths;
					my $command_root = $class_name;
					$command_root =~ s/Whatbot\:\:Command\:\://;
					$command_root = lc($command_root);
				
					# Instantiate
					my $config;
					if (defined $self->config->commands->{lc($name)}) {
						$config = $self->config->commands->{lc($name)};
					}
					if ( $config and ref($config) and defined $config->{enabled} and not $config->{enabled} ) {
						$self->log->write( '-> ' . $class_name . ' disabled in config.' );
						next;
					}

					my $new_command = $class_name->new(
						'my_config' => $config,
						'name'      => $command_root,
					);

					# Determine runpaths
					foreach my $function ( @{Class::Inspector->functions($class_name)} ) {
						# Get subroutine attributes
						$self->determine_subroutine_attributes(
							$new_command,
							$class_name,
							$function,
							\@run_paths,
							\%end_paths
						);
					}

					$new_command->command_priority('Extension') unless ( $new_command->command_priority );
					unless ( 
						lc($new_command->command_priority) =~ /(extension|last)/
						and $self->skip_extensions
					) {
						# Add to command structure and name to command map
						$command{ lc($new_command->command_priority) }->{$class_name} = \@run_paths;
						$self->command_name->{$class_name} = $new_command;
						$command_short_name{$command_root} = $new_command;
				
						$self->log->write( '-> ' . ref($new_command) . ' loaded.' );
					}
				
					# Insert end paths
					for ( my $i = 0; $i < scalar(@run_paths); $i++ ) {
						if ( $end_paths{ $run_paths[$i]->{'function'} } ) {
							$run_paths[$i]->{'stop'} = 1;
						}
					}
				}
			}
		}
	
		$self->command(\%command);
		$self->command_short_name(\%command_short_name);
	}

=item handle_message( Whatbot::Message $message )

Run incoming message through commands, parse responses, and deliver back to IO.

=cut

	method handle_message ( $message, $me? ) {
		my @messages;
		foreach my $priority ( qw( primary core extension last ) ) {
			last if ( @messages and $priority =~ /last/ );
		
			# Iterate through priorities, in order, check for commands that can
			# receive content
			foreach my $command_name ( keys %{ $self->command->{$priority} } ) {
				my $command = $self->command_name->{$command_name};
				next if ( $command->require_direct and !$message->is_direct );

				# Check each method corresponding to a registered runpath to see
				# if it cares about our content
				foreach my $run_path ( @{ $self->command->{$priority}->{$command_name} } ) {
					next unless ( $run_path->{'match'} or $run_path->{'function'} );
					next if ( $run_path->{'event'} );

					my $listen = ( $run_path->{'match'} or '' );
					my $function = $run_path->{'function'};

					my $content_match = ( $run_path->{'use_text'} ? $message->text : $message->content );
					if ( $listen eq '' or my (@matches) = $content_match =~ /$listen/i ) {
						if ( my $filter = $run_path->{'filter'} ) {
							for ( my $i = 0; $i < scalar(@matches); $i++ ) {
								$matches[$i] = $filter->($matches[$i]);
							}
						}
						my $result = eval {
							$command->$function( $message, \@matches );
						};
						my $error = $@;
						return $self->_return_error( $command_name, $message, $error ) if ($error);
						$self->_parse_result( $command_name, $message, $result, \@messages );
					
						# End processing for this command if StopAfter was called.
						last if ( $run_path->{'stop'} );
					}
				}
			}
		}
	
		return \@messages;
	}

=item handle_event( $event, $event_info )

Run incoming event through commands, parse responses, and delivery back to IO.

=cut

	# dear god refactor
	method handle_event ( $target, Str $event, HashRef $event_info, $me? ) {
		my ( $io, $context ) = split( /:/, $target );

		my @messages;
		foreach my $priority ( qw( primary core extension last ) ) {
			last if ( @messages and $priority =~ /(extension|last)/ );
		
			# Iterate through priorities, in order, check for commands that can
			# receive content
			foreach my $command_name ( keys %{ $self->command->{$priority} } ) {
				my $command = $self->command_name->{$command_name};

				# Check each method corresponding to a registered runpath to see
				# if it cares about our content
				foreach my $run_path ( @{ $self->command->{$priority}->{$command_name} } ) {
					next unless ( $run_path->{'event'} and $run_path->{'event'} eq $event );

					my $function = $run_path->{'function'};
					my $message = Whatbot::Message->new({
						'from' => $me,
						'to'   => $context,
						'text' => '',
						'me'   => $me,
					});
					my $result = eval {
						$command->$function( $target, $event_info );
					};
					my $error = $@;
					return $self->_return_error( $command_name, $message, $error ) if ($error);
					$self->_parse_result( $command_name, $message, $result, \@messages );
				
					# End processing for this command if StopAfter was called.
					last if $run_path->{'stop'};
			
				}
			}
		}
	
		return \@messages;
	}

	method dump_command_map {
		foreach my $priority ( qw( primary core extension ) ) {
			my $commands = 0;
		
			$self->log->write( uc($priority) . ':' );
		
			foreach my $command_name ( keys %{ $self->command->{$priority} } ) {
				foreach my $run_path ( @{ $self->command->{$priority}->{$command_name} } ) {
					if ( $run_path->{'match'} ) {
						$self->log->write( ' /' . $run_path->{'match'} . '/ => ' . $command_name . '->' . $run_path->{'function'} );
					} elsif ( $run_path->{'event'} ) {
						$self->log->write( ' Event "' . $run_path->{'event'} . '" => ' . $command_name . '->' . $run_path->{'function'} );
					}
					
					$commands++;
				}
			}
		
			$self->log->write(' none') unless ($commands);
		}
	}

	method error_override ( Str $class, Str $name ) {
		$self->log->error( $class . ': More than one command being registered for "' . $name . '".' )
	}

	method error_regex ( Str $class, Str $function, Str $regex ) {
		$self->log->error( 
			$class . ': Invalid arguments (' . $regex . ') in method "' . $function . '".'
		);
	}

	method add_run_path( $run_paths, $match, $function ) {
		my $obj = {
			'function' => $function
		};
		if ( $match =~ /\{!user/ ) {
			$match =~ s/\{!user\}/(\{!user=[\\w_]+?\}|[\\w_]+)/g;
			$obj->{'use_text'} = 1;
			$obj->{'filter'} = sub { my $a = shift(@_); $a =~ s/\{!user=([\w_]+?)\}/$1/g; return $a; };
		}
		$obj->{'match'} = qr/$match/;
		push( @$run_paths, $obj );
		return;
	}

	method add_event( $run_paths, $event, $function ) {
		push(
			@$run_paths,
			{
				'event'    => $event,
				'function' => $function
			}
		);
		return;
	}

	method determine_subroutine_attributes( $new_command, $class_name, $function, $run_paths, $end_paths ) {
		my $full_function = $class_name . '::' . $function;
		my $coderef = \&$full_function;

		if ( my $attributes = $new_command->fetch_attributes($coderef) ) {
			foreach my $attribute ( @{$attributes} ) {
				my ( $command, @arguments ) = @$attribute;
			
				if ( $command eq 'Command' ) {
					my $register = '^' . $new_command->name . ' +' . $function . ' *([^\b]+)*';
					if ( $self->command_name->{$register} ) {
						$self->error_override( $class_name, $register )
					} else {
						$self->add_run_path( $run_paths, $register, $function );
					}
				

				} elsif ( $command eq 'CommandRegEx' ) {
					my $arg = shift(@arguments);
					my $register = '^' . $new_command->name . ' +' . $arg;
					if ( $self->command_name->{$register} ) {
						$self->error_override( $class_name, $register )
					} else {
						$self->add_run_path( $run_paths, $register, $function );
					}
					
				} elsif ( $command eq 'GlobalRegEx' ) {
					my $arg = shift(@arguments);
					if ( $self->command_name->{$arg} ) {
						$self->error_override( $class_name, $arg )
					} else {
						$self->add_run_path( $run_paths, $arg, $function );
					}
				
				} elsif ( $command eq 'Monitor' ) {
					$self->add_run_path( $run_paths, '.*', $function );
				
				} elsif ( $command eq 'Event' ) {
					my $arg = shift(@arguments);
					$self->add_event( $run_paths, $arg, $function );
				
				} elsif ( $command eq 'StopAfter' ) {
					$end_paths->{$function} = 1;
				
				} else {
					$self->log->error(
						$class_name . ': Invalid attribute "' . $command . '" on method "' . $function . '", ignoring.'
					);
				}
			}
		}
	}

	method _return_error( $command_name, $message, $error ) {
		$self->log->error( 'Failure in ' . $command_name . ': ' . $error );
		$self->log->error( Devel::StackTrace->new->as_string );
		return $message->reply({
			'text' => $command_name . ' completely failed at that last remark.',
		});
	}

	# Parse the result from a event or message call
	method _parse_result( $command_name, $message?, $result?, ArrayRef $messages? ) {
		$message ||= Whatbot::Message->new({
			'from' => '',
			'to'   => 'public',
			'text' => '',
		});
		if ( defined $result ) {
			last if ( $result eq 'last_run' );
	
			$self->log->write( '%%% Message handled by ' . $command_name )
				unless ( defined $self->config->io->[0]->{'silent'} );
			$result = [ $result ] if ( ref($result) ne 'ARRAY' );
		
			foreach my $result_single ( @$result ) {
				my $outmessage;
				if ( ref($result_single) eq 'Whatbot::Message' ) {
					$outmessage = $result_single;
				} else {
					$outmessage = $message->reply({
						'text' => $result_single,
					});
				}
				push( @$messages, $outmessage );
			}
		}
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
