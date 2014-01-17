###########################################################################
# Seen.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Database::Table::Seen - Database functionality for seen.

=head1 SYNOPSIS

 # In whatbot
 $self->model('Seen')->seen( 'example', 'Hello, everyone!' );

=head1 DESCRIPTION

whatbot::Database::Table::Factoid provides database functionality for seen.

=head1 METHODS

=over 4

=cut

class whatbot::Database::Table::Seen extends whatbot::Database::Table {

    method BUILD(...) {
        $self->init_table({
            'name'        => 'seen',
            'primary_key' => 'seen_id',
            'indexed'     => ['user'],
            'defaults'    => {
                'timestamp' => { 'database' => 'now' }
            },
            'columns'     => {
                'seen_id' => {
                    'type'  => 'serial'
                },
                'timestamp' => {
                    'type'  => 'integer'
                },
                'user' => {
                    'type'  => 'varchar',
                    'size'  => 255
                },
                'message' => {
                    'type'  => 'text'
                }
            }
        });
    }

=item seen( $user, $message? )

If a user is provided, return the row corresponding to the last seen message
from that user. If a message is provided, store that seen, and return the row.

=cut

    method seen( Str $user, Str $message? ) {
    	$user = lc($user);
    	
    	my $seen_row = $self->search_one({
    	    'user' => $user
    	});
    	if ( defined $message ) {
    	    $seen_row->delete() if ( defined $seen_row );
    	    return $self->create({
    	        'user'      => $user,
    	        'message'   => $message
    	    });
    	}

    	return $seen_row;
    }
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
