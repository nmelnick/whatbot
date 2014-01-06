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
use Number::Format;
use namespace::autoclean;

sub register {
	my ($self) = @_;
	
	$self->command_priority('Extension');
	$self->require_direct(0);
}

sub free_form : GlobalRegEx('^\(*\-?\d[\d\.]*\+[\+\-\*\/][\d\(\)\+\-\*\/\.]*\d\)*$') {
	my ( $self, $message ) = @_;
	
	return $self->parse_message( $message, [ $message->content ]);
}

sub what_the_hell_mike : GlobalRegEx('^\s*\d+\s*[\+\-\*\/]\s*\d+$') {
	my ( $self, $message ) = @_;
	
	return $self->parse_message( $message, [ $message->content ]);
}

sub parse_message : GlobalRegEx('^calc (.*)') {
	my ( $self, $message, $captures ) = @_;

	my $expression = $captures->[0];
    
	return undef unless $expression;

	return $message->from . ": " . $self->_parse($expression);
}

sub rand : GlobalRegEx('^rand (.*)') {
  my ( $self, $message, $captures ) = @_;

  my $list = $captures->[0];

  return undef unless $list;

  my @choices = split(' ', $list);

  return $message->from . ": " . $choices[rand @choices];
}

sub _parse {
	my ( $self, $expression ) = @_;

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

  my $formatter = new Number::Format();
  my @pretty_results = map { 
    if($_ =~ /^\d+$/) {
      $formatter->format_number($_);
    } else {
      $_;
    }
    
  } @result;

	return join(', ', @pretty_results);
}

__PACKAGE__->meta->make_immutable;

1;
