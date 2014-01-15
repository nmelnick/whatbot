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
use namespace::autoclean;

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Primary');
	$self->require_direct(0);
}

sub refresh : Command {
	my ( $self, $message ) = @_;
	
	return unless ( $self->_has_permission($message) );
	
	$self->controller->build_command_map();
	return 'Rebuilt command set: ' . scalar(@{$self->controller->command_name}) . ' commands loaded.';
}

sub version : Command {
	my ( $self, $message ) = @_;
	
	return unless ( $self->_has_permission($message) );
	return 'whatbot ' . $self->parent->version;
}

sub rehash : Command {
	my ( $self, $message ) = @_;
	
	return unless ( $self->_has_permission($message) );
	
	system( 'nice ' . $ENV{_} . ' ' . join( ' ', @ARGV ) . ' &' );
	exit(1);
}

sub error : Command {
    my ( $self, $message ) = @_;
	
	return unless ( $self->_has_permission($message) );
	return $self->log->last_error;
}

sub retrieve : Command {
	my ( $self, $message ) = @_;
	
	return unless ( $self->_has_permission($message) );
	
	my $content = $message->content;
	$content =~ s/^admin *retrieve *//;
	my ( $model ) = split( / /, $content );
	$content =~ s/.*?(\{.*?\})$/$1/;
	
	my $params = eval "$content";
	my $row;
	eval {
    	$row = $self->model($model)->search_one($params);
	};
	if ($@) {
	    return 'Error executing: ' . $@;
	} else {
	    if ($row) {
	        return join( ', ', map { $row->columns->[$_] . ' => "' . $row->column_data->[$_] . '"' } 0..( scalar(@{ $row->column_data }) - 1) );
	    } else {
	        return 'Nothing found for that query.';
	    }
	}
	
	return;
}

sub warnvar : Command {
	my ( $self, $message, $var ) = @_;

	warn Data::Dumper::Dumper( eval "$var" );
	return 'Check the log.';
}

sub throw : Command {
    my ( $self, $message, $args ) = @_;

    my ( $io_search, @message_split ) = split( / /, $args->[0] );
    my $new_message = whatbot::Message->new(
        'to'             => '',
        'from'           => '',
        'content'        => join( ' ', @message_split ),
		'base_component' => $self->parent->base_component
    );
    foreach my $io ( keys %{ $self->ios } ) {
        if ( $io =~ /$io_search/ ) {
            $self->ios->{$io}->send_message($new_message);
            last;
        }
    }
    
    return;
}

sub alias : Command {
	my ( $self, $message, $args ) = @_;
	
	return unless ( $self->_has_permission($message) );

	my ( $user, $alias ) = split( / /, join( ' ', @$args ) );
	return unless ( $user and $alias );

	if ( my $owner = $self->model('UserAlias')->user_for_alias($alias) ) {
		return 'The alias "' . $alias . '" is already set for user "' . $owner . '".'
	}
	if ( my $aliases = $self->model('UserAlias')->aliases_for_user($alias) ) {
		return 'The alias "' . $alias . '" is already a user with other aliases.' if (@$aliases);
	}

	if ( $self->model('UserAlias')->alias( $user, $alias ) ) {
		return 'The user "' . $user . '" is now also known as "' . $alias . '".';
	}
	return;
}

sub unalias : Command {
	my ( $self, $message, $args ) = @_;
	
	return unless ( $self->_has_permission($message) );

	my ( $user, $alias ) = split( / /, join( ' ', @$args ) );
	return unless ( $user and $alias );

	if ( $self->model('UserAlias')->remove( $user, $alias ) ) {
		return 'Removed.';
	}

	return 'That combination was not found.';
}

sub convertalias : Command {
	my ( $self, $message, $args ) = @_;

	return unless ( $self->_has_permission($message) );

	my ( $alias ) = split( / /, join( ' ', @$args ) );
	return unless ( $alias );
	$alias = lc($alias);

	my $user = $self->model('UserAlias')->user_for_alias($alias);
	unless ($user) {
		return 'That alias is not assigned to a user.';
	}

	my $karmas = $self->model('Karma')->search({ 'user' => { 'LIKE' => $alias } });
	foreach my $karma (@$karmas) {
		$karma->user($user);
		$karma->save();
	}
	$karmas = $self->model('Karma')->search({ 'subject' => $alias });
	foreach my $karma (@$karmas) {
		$karma->subject($user);
		$karma->save();
	}
	return 'Done.';
}

sub _has_permission {
	my ( $self, $message ) = @_;

	return (
		defined $self->my_config
		and $message->from eq $self->my_config->{'user'}
	);
}

__PACKAGE__->meta->make_immutable;

1;
