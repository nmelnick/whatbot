###########################################################################
# Quote.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class whatbot::Database::Table::Quote extends whatbot::Database::Table {
	method BUILD(...) {
		$self->init_table({
			'name'        => 'quote',
			'primary_key' => 'quote_id',
			'indexed'     => [ 'user', 'quoted' ],
			'defaults'    => {
				'timestamp' => { 'database' => 'now' }
			},
			'columns'     => {
				'quote_id' => {
					'type'  => 'integer'
				},
				'timestamp' => {
					'type'  => 'integer'
				},
				'user' => {
					'type'  => 'varchar',
					'size'  => 255
				},
				'quoted' => {
					'type'  => 'varchar',
					'size'  => 255
				},
				'content' => {
					'type'  => 'text'
				},
			}
		});
	}

    before create ($column_data) {
    	my $content = $column_data->{content};
    	if ( my $quote = $self->search_one({ 'content' => $content }) ) {
    		die bless( { 'user' => $quote->user }, 'Exception::QuoteExists' );
    	}
    	return;
    }

    method get_random( $user? ) {
    	my $params = {
			'_order_by' => 'RANDOM()',
			'_limit'    => 1,
		};
		if ($user) {
			$params->{'quoted'} = { 'LIKE' => $user },
		}
		return $self->search_one($params);
    }
}

1;

=pod

=head1 NAME

whatbot::Database::Table::Quote - Database model for Quote

=head1 SYNOPSIS

 use whatbot::Database::Table::Quote;

=head1 DESCRIPTION

whatbot::Database::Table::Quote does stuff.

=head1 METHODS

=over 4

=back

=head1 INHERITANCE

=over 4

=item whatbot::Component

=over 4

=item whatbot::Database::Table

=over 4

=item whatbot::Database::Table::Quote

=back

=back

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
