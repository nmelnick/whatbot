###########################################################################
# Location.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Command::Role::Location - Provide methods to convert a string location
to coordinates.

=head1 SYNOPSIS

 package Whatbot::Command::Example;
 use Moose;
 BEGIN { extends 'Whatbot::Command'; with 'Whatbot::Command::Role::Location'; }
 
sub message : Monitor {
   my ( $self, $message_ref ) = @_;

   my $location = $self->convert_location($message_ref->content);
   return join(", ", @);
 }

=head1 DESCRIPTION

Whatbot::Command::Role::Location provides methods to convert a string location,
such as "London, United Kingdom" to a coordinate set representing latitude and
longitude.

=head1 PUBLIC METHODS

=over 4

=cut

role Whatbot::Command::Role::Location {
    use Geo::Coder::OSM;

=item convert_location( $string_location )

Given a location description, return a hashref containing "coordinates" as an
arrayref of latitude and longitude, and "display", as the calculated display
name of the given location. If the location was not found, coordinates will be
provided as [0, 0], and the display will be the provided string.

 {
   "coordinates" => [51.5283, -0.3817],
   "display"     => "London, United Kingdom"
 }

=cut

    method convert_location( Str $location ) {
        my $osm = Geo::Coder::OSM->new();
        my $resolved = $osm->geocode( location => $location );
        if ($resolved and $resolved->{'lat'}) {
            return {
                'coordinates' => [ $resolved->{'lat'}, $resolved->{'lon'} ],
                'display'     => join( ', ',
                    ( $resolved->{'address'}->{'city'} or $resolved->{'address'}->{'town'} ),
                    $resolved->{'address'}->{'state'},
                    $resolved->{'address'}->{'country'}
                ),
            };
        }
        
        return {
            'coordinates' => [0, 0],
            'display'     => $location,
        };
    }
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
