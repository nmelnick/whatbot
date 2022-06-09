###########################################################################
# UserAgent.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Role::UserAgent - Role to provide a default user agent.

=head1 SYNOPSIS

 class Whatbot::Foo with Whatbot::Role::UserAgent {
   method foo {
     $self->ua->get();
   }
 }

=head1 DESCRIPTION

Whatbot::Role::UserAgent provides a LWP::UserAgent to an existing class.

=head1 METHODS

=over 4

=cut

role Whatbot::Role::UserAgent {
  use LWP::UserAgent ();

=item ua()

Returns a single instance of LWP::UserAgent for this class.

=cut

  has 'ua' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub {
      LWP::UserAgent->new(
        agent => 'Mozilla/5.0 (Windows NT 6.3; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2049.0 Safari/537.36',
      );
    }
  );
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
