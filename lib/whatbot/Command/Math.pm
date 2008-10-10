###########################################################################
# whatbot/Command/Math.pm
###########################################################################
# Do some math.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Math;
use Moose;
BEGIN { extends 'whatbot::Command' }

use Math::Expression;

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub free_form : GlobalRegEx('^[\d\+\-\*\/ ]+[\d\+\-\*\/ ]+$') {
	my ( $self, $message ) = @_;
	
	return $self->parse_message($message);
}

sub parse_message : CommandRegEx('') {
	my ( $self, $message ) = @_;

	my $expression = $message->content;
    $expression =~ s/^calc\s*//i;
    
	return undef unless ( $expression and $expression =~ /\d/ );

	return $message->from . ": " . $self->_parse($expression);
}

sub _parse {
	my ($self, $expression) = @_;

	my @lines = split(/;/, $expression);
	my $multiline = (@lines > 1);

	my $env = Math::Expression->new;

	my @errbuf;

	$env->SetOpt(
	    PrintErrFunc => sub { 
	        my $format = shift;
	        push(@errbuf, sprintf($format, @_)); 
	    } 
	);

	my $line_n = 0;
	my @result;
	foreach my $line (@lines) {
		$line_n++;
		my $tree = $env->Parse($line);

		if (!$tree) {
			return ((@lines > 1 ? "Error line $line_n: " : "Error: ") .
		 		(@errbuf ? join(', ', @errbuf) : "wtf"));
		}
		@result = $env->Eval($tree);
	}

	return join(', ', @result);
}

1;
