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
	
	system( 'nice ' . $ENV{_} . ' ' . join( ' ', @ARGV ) . ' &' );
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
		    my $rev = $1;
			return 'Now at svn r' . $rev . '. Changed: ' . $self->last( $message, undef, $rev);
		}
	} else {
		warn $basedir;
		return 'This is not a SVN install.';
	}
	return undef;
}

sub last : Command {
    my ( $self, $message, $captures, $rev ) = @_;
	
	return undef unless ( defined $self->my_config and $message->from eq $self->my_config->{'user'} );
    
    my $basedir = realpath($0);
    my $appname = $0;
    $appname =~ s/.*?\///g;
    $basedir =~ s/\/$appname$//;
    $basedir =~ s/\/bin$//;
    unless ($rev) {
    	if ( -e $basedir . '/.svn' ) {
    		my $inf = `svn up $basedir`;
    		$inf = `svn info $basedir`;
    		if ($inf =~ /Revision:\s+(\d+)/) {
    		    $rev = $1;
    		}
    	} 
    }
    my $log = `svn log $basedir -r$rev`;
    $log =~ s/\-\-\-\-+.*?[^\n]+(.*?)\-\-\-\-+/$1/s;
    $log =~ s/\n//g;
    
    return ( defined $message ? 'Changed in r' . $rev . ': ' : '' ) . $log;
}

sub error : Command {
    my ( $self, $message ) = @_;
	
	return undef unless ( defined $self->my_config and $message->from eq $self->my_config->{'user'} );
	return $self->log->last_error;
}

sub retrieve : Command {
	my ( $self, $message ) = @_;
	
	return undef unless ( defined $self->my_config and $message->from eq $self->my_config->{'user'} );
	
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

__PACKAGE__->meta->make_immutable;

1;

