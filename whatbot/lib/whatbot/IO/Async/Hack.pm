# From http://www.perlmonks.org/?node_id=865070
package whatbot::IO::Async::Hack;
use strict;
use warnings;
use Errno;
use Net::HTTP::Methods;
use IO::Socket::SSL;

no warnings 'redefine';

my $old_read_entity   = \&Net::HTTP::Methods::read_entity_body;
my $old_read_response = \&Net::HTTP::Methods::read_response_headers;

*Net::HTTP::Methods::my_readline           = \&my_readline;
*Net::HTTP::Methods::my_read               = \&my_read;
*Net::HTTP::Methods::read_entity_body      = \&my_read_entity;
*Net::HTTP::Methods::read_response_headers = \&my_read_response;

sub my_read_response {
    my @vals = eval { $old_read_response->(@_); };
    if ($@) {
        return if ( $@ =~ /^Non-blocking/ );
        die $@;
    }
    return @vals;
}

sub my_read_entity {
    my $val = eval { $old_read_entity->(@_); };
    if ($@) {
        return if ( $@ =~ /^Non-blocking/ );
        die $@;
    }
    return $val;
}

sub my_read {
    die if @_ > 3;
    my $self = shift;
    my $len  = $_[1];
    for ( ${*$self}{'http_buf'} ) {
        if (length) {
            $_[0] = substr( $_, 0, $len, "" );
            return length( $_[0] );
        }
        else {
            my $n = $self->sysread( $_[0], $len );
            die "Non-blocking\n" if ( !defined $n && $!{EAGAIN} );
            return $n;
        }
    }
}

sub my_readline {
    my $self = shift;
    my $what = shift;
    for ( ${*$self}{'http_buf'} ) {
        my $max_line_length = ${*$self}{'http_max_line_length'};
        my $pos;
        while (1) {

            # find line ending
            $pos = index( $_, "\012" );
            last if $pos >= 0;
            die "$what line too long (limit is $max_line_length)"
              if $max_line_length && length($_) > $max_line_length;

            # need to read more data to find a line ending
          READ:
            {
                my $n = $self->sysread( $_, 1024, length );
                unless ( defined $n ) {
                    redo READ if $!{EINTR};
                    die "Non-blocking\n" if ( $!{EAGAIN} );

                    # if we have already accumulated some data let's at least
                    # return that as a line
                    die "$what read failed: $!" unless length;
                }
                unless ($n) {
                    return undef unless length;
                    return substr( $_, 0, length, "" );
                }
            }
        }
        die "$what line too long ($pos; limit is $max_line_length)"
          if $max_line_length && $pos > $max_line_length;

        my $line = substr( $_, 0, $pos + 1, "" );
        $line =~ s/(\015?\012)\z// || die "Assert";
        return wantarray ? ( $line, $1 ) : $line;
    }
}

package Net::HTTP::NB;
use vars qw(@ISA);

@ISA = qw(Net::HTTP);

sub new {
    my $class = shift;
    my %args  = @_;
    return Net::HTTPS->new(@_) if ( $args{PeerPort} == 443 );
    return $class->SUPER::new(@_);
}

package Net::HTTPS;
use vars qw(@ISA);
@ISA = qw(IO::Socket::SSL Net::HTTP::Methods);

sub configure {
    my ( $self, $cnf ) = @_;
    $self->http_configure($cnf);
}

sub http_connect {
    my ( $self, $cnf ) = @_;
    $self->SUPER::configure($cnf);
}

1;
