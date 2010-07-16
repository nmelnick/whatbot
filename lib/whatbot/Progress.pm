###########################################################################
# whatbot/Progress.pm
###########################################################################
# progress bar for whatbot
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::Progress {
    has 'max'              => ( is => 'rw', isa => 'Int' );
    has 'restrict_updates' => ( is => 'rw', isa => 'Int' );
    has 'show_count'       => ( is => 'rw', isa => 'Int' );

    method update ( Int $current ) {
        return if ( $self->restrict_updates and $current % $self->restrict_updates != 0 );
        return unless ( $self->max and $self->max > 0 );

        my $pct = int( ( $current / $self->max ) * 100 );
        my $line = '[';
        for ( my $c = 0; $c < int($pct * 0.7); $c++ ) {
            $line .= '=';
        }
        for ( my $c = 0; $c < (65 - int($pct * 0.65)); $c++ ) {
            $line .= '-';
        }
        $line .= '] ' . $pct . '% ';
        if ( $self->show_count ) {
            $line .= $current . '/' . $self->max;
        }
        for ( my $c = 0; $c < ( 80 - length($line) ); $c++ ) {
            $line .= ' ';
        }
        $line .= "\r";
        print $line;
    }

    method finish {
        $self->restrict_updates(0);
        $self->update( $self->max );
        print "\n";
    }
}

1;

=pod

=head1 NAME

whatbot::Progress - Provides a basic progress meter

=head1 SYNOPSIS

 use whatbot::Progress;
 
 my $progress = new whatbot::Progress (
    'restrict_updates' => 10,
    'max'              => 100,
    'show_count'       => 1
 );
 for ( my $i = 0; $i <= 100; $i++ ) {
     $progress->update($i);
 }
 $progress->finish();

=head1 DESCRIPTION

whatbot::Progress provides a simple command line progress bar without any
dependencies beyond what whatbot requires.

=head1 PUBLIC ACCESSORS

=over 4

=item restrict_updates

Divisor of the current progress where the progress bar should be updated.
Leaving this undefined will cause the progress bar to update every time
'update' is called, otherwise, will only update per multiple.

=item max

Value of the 100% mark

=item show_count

Display the current count at the end of the progress bar. This updates
depending on the value of 

=back

=head1 METHODS

=over 4

=item update

Update the progress bar with the given value

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut