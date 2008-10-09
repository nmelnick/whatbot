###########################################################################
# whatbot/Command/Math.pm
###########################################################################
# Do some math.
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Math;
use Moose;
extends 'whatbot::Command';

use Math::Expression;

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Extension");
	$self->listenFor([
	    qr/^calc/i,
	    qr/^[\d\+\-\*\/ ]+$/
	]);
	$self->requireDirect(0);
}

sub parseMessage {
	my ($self, $messageRef) = @_;

	my $expression = $messageRef->content;
    $expression =~ s/^calc\s*//i;
    
	return undef unless ( $expression and $expression =~ /\d/ );

	return $messageRef->from . ": " . $self->_parse($expression);
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
