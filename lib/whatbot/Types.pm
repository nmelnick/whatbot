package whatbot::Types;
use strict;
use warnings;
use MooseX::Types -declare => [qw( HTTPRequest whatbotMessage )];
use Moose::Util::TypeConstraints;

use HTTP::Request ();
use whatbot::Message ();

subtype HTTPRequest, as class_type('HTTP::Request');
subtype whatbotMessage, as class_type('whatbot::Message');

1;

=pod

=head1 NAME

whatbot::Types - Type definitions for whatbot.

=head1 TYPES

=over 4

=item HTTP::Request

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
