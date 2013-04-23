###########################################################################
# whatbot/Database/Table/Paste.pm
###########################################################################
#
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;

class whatbot::Database::Table::Paste extends whatbot::Database::Table {

    method BUILD ($) { 
        $self->init_table({
            'name'        => 'paste',
            'primary_key' => 'paste_id',
            'indexed'     => [ 'user', 'destination' ],
            'defaults'    => {
                'timestamp' => { 'database' => 'now' }
            },
            'columns'     => {
                'paste_id' => {
                    'type'  => 'integer'
                },
                'timestamp' => {
                    'type'  => 'integer'
                },
                'user' => {
                    'type'  => 'varchar',
                    'size'  => 255
                },
                'destination' => {
                    'type'  => 'varchar',
                    'size'  => 255
                },
                'summary' => {
                    'type'  => 'text'
                },
                'content' => {
                    'type'  => 'text'
                },
            }
        });
    }

}

1;

=pod

=head1 NAME

whatbot::Database::Table::Paste - Database model for paste

=head1 SYNOPSIS

 use whatbot::Database::Table::Paste;

=head1 DESCRIPTION

whatbot::Database::Table::Paste does stuff.

=head1 METHODS

=over 4

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Database::Table

=over 4

=item whatbot::Database::Table::Paste

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
