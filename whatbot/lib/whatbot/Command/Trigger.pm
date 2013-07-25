###########################################################################
# whatbot/Command/Trigger.pm
###########################################################################
# Set up trigger words, like factoid, but searches within an entire
# message
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Trigger;
use Moose;
BEGIN { extends 'whatbot::Command'; }
use namespace::autoclean;

has triggers => ( is => 'rw', isa => 'HashRef' );

sub register {
	my ( $self ) = @_;
	
	$self->command_priority('Last');
	$self->require_direct(0);
	
	$self->triggers( $self->model('Soup')->get_hashref() );
	
	return;
}

sub set : Command {
	my ( $self, $message, $captures ) = @_;
	
	my @set_line = split( //, join( ' ', @$captures ) );
	
	if ( $set_line[0] eq '/' ) {
		shift(@set_line);
		my ( $trigger, $escape, $has_trigger, $response );
		while (@set_line) {
			my $char = shift(@set_line);
			
			if ( $char eq '/' ) {
				if ($escape) {
					$trigger .= '\/';
					next;
				} else {
					$has_trigger++;
					last;
				}
			} elsif ( $char eq "\\" ) {
				$escape++;
				next;
			} else {
				$trigger .= "\\" if ($escape);
				$trigger .= $char;
			}
			$escape = 0;
		}
		if ($has_trigger) {
			$response = join( '', @set_line );
			$response =~ s/^\s+//;
			
			$self->model('Soup')->set( $trigger, $response );
			$self->triggers( $self->model('Soup')->get_hashref() );
			return 'Trigger set.';
		}
	}
	
	return 'Invalid trigger: You must start with a regular expression inside '
	     . 'two forward slashes, followed by the response.';
}

sub unset : Command {
	my ( $self, $message, $captures ) = @_;
	
	my $unset = join( ' ', @$captures );
	$unset =~ s/^\///;
	$unset =~ s/\/$//;
	my $get = $self->model('Soup')->get($unset);
	if ($get) {
		$self->model('Soup')->clear($unset);
		$self->triggers( $self->model('Soup')->get_hashref() );
		return 'Removed trigger.';
	}
	return 'I could not find that trigger';
}

sub stats : Command {
	my ( $self ) = @_;
	
	my $trigger = scalar( keys %{ $self->triggers } );
	return 'There ' . ( $trigger == 1 ? 'is ' : 'are ' ) . $trigger . ' trigger' . ( $trigger == 1 ? '' : 's' ) . ' set.';
}

sub listener : GlobalRegEx('(.+)') {
	my ( $self, $message ) = @_;
	
	foreach my $trigger ( keys %{ $self->triggers } ) {
		if ( my @captures = $message->content =~ /$trigger/ ) {
			my $response = $self->triggers->{$trigger};
			
			# Capture a <reply> if necessary
			if ( $response =~ /<reply>/ ) {
				$response =~ s/^<reply> +//;
			}

			# Replace captures within response
			if (@captures) {
				for ( my $index = 1; $index <= scalar(@captures); $index++ ) {
					my $capture = $captures[$index - 1];
					$response =~ s/\$$index/$capture/g;
				}
			}

			return $response;
		}
	}
	return;
}

sub help {
    my ( $self ) = @_;
    
    return [
        'Trigger will listen for snippets within incoming messages and respond ' .
        'accordingly. So, if you want the bot to scream every time someone ' .
        'says the magic word, enter "trigger set /magic word/ /me screams!".',
        ' * "set /regex/ response" -- set a trigger',
        ' * unset /regex/ -- unset a trigger',
        ' * stats -- show how many triggers are set'
    ];
}

__PACKAGE__->meta->make_immutable;

1;
