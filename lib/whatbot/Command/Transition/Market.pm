###########################################################################
# whatbot/Command/Market.pm
###########################################################################
# grabs currency rates and stocks, for lols
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Command::Market;
use Moose;
extends 'whatbot::Command';
use Finance::Quote;
use String::IRC; # for colors!

has 'quote' => (
	is		=> 'ro',
	isa		=> 'Finance::Quote',
	default => sub { Finance::Quote->new; }
);

sub register {
	my ($self) = @_;
	
	$self->commandPriority("Extension");
	$self->listenFor(qr/^market (.*)/io);
	$self->requireDirect(0);
        $self->quote->timeout(15);
        $self->quote->require_labels(qw/last p_change name/);
}

sub parseMessage {
	my ($self, $messageRef) = @_;

	$_ = $messageRef->content;
	my ($target) = m/^market (.*)$/io;
        return "what" unless $target;

        if ($target =~ m!/!o) {
            my ($to_cur, $from_cur) = ($target =~ m!^([a-z]+)/([a-z]+)$!io);

            if (!defined($to_cur) || !defined($from_cur)) {
                return "wtf is $target";
            }
            
            my $rate = $self->quote->currency($from_cur, $to_cur);

            if (!$rate) {
                return "I can't get a rate for $from_cur/$to_cur.";
            }
            return "1 $from_cur == $rate $to_cur";
        }
         
        # from here on we're dealing with stocks
	my ($exchange, $stocklist) =
            ($target =~ m/^(?:([^:]+):)?([^:]+)$/);
        my @stocks = map { uc } split /,/, $stocklist;
        
        $exchange = "nyse" unless defined($exchange);
        my $info = $self->quote->fetch($exchange, @stocks);

        if (!$info) {
            return "I couldn't find anything for $target.";
        }

        my @results;
        
        foreach my $symbol (@stocks) {
            # this API is gay

            if (! $info->{$symbol,"success"}) {
                push @results, "$symbol: " . $info->{$symbol,"errormsg"};
                next;
            }

            my ($corpname, $lastprice, $pchange) = map{ $info->{$symbol,$_} } qw(name last p_change);

            my $pchangestr = String::IRC->new("$pchange%");
            $pchangestr =~ /^\-/ ? $pchangestr->red : $pchangestr->green;

            push @results, "$symbol ($corpname) $lastprice $pchangestr";
        }

        return join(" - ", @results);
}

1;

