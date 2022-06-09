###########################################################################
# Whatbot/Command/Dashboard.pm
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;
use Whatbot::Command;

class Whatbot::Command::Dashboard
  extends Whatbot::Command
  with Whatbot::Command::Role::Web, Whatbot::Command::Role::BootstrapTemplate {
  use Whatbot::Helper::Bootstrap::Link;

  method register(...) {
    $self->command_priority('Core');
    $self->require_direct(0);

    $self->web(
      '/',
      \&dashboard
    );
  }

  method help( $message?, $captures? ) : Command {
    return 'Dashboard is at ' . $self->web_url() . '.';
  }

  method dashboard( $httpd, $req ) {
    my %state = (
      'applications' => [ sort { $a cmp $b } @Whatbot::Helper::Bootstrap::applications ],
    );
    return $self->render( $req, _dashboard_tt2(), \%state );
  }

sub _dashboard_tt2 {
  my $string = q{
    <h2>Commands</h2>
    <div class="list-group">
[% FOREACH app IN applications %]
  <a href="[% app.1 %]" class="list-group-item">[% app.0 %]</a>
[% END %]
[% IF applications.size == 0 %]
  <li class="list-group-item">No web-capable commands installed.</li>
[% END %]
    </div>
};
  return \$string;
}
}

1;

=pod

=head1 NAME

Whatbot::Command::Dashboard - Provide an index page

=head1 DESCRIPTION

Whatbot::Command::Dashboard provides a 'home page' for whatbot. This could
easily by changed by subclassing or overriding Dashboard.

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
