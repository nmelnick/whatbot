###########################################################################
# Link.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Helper::Bootstrap::Link - Represents a Bootstrap link.

=head1 SYNOPSIS

 my $link = Whatbot::Helper::Bootstrap::Link->new({
   'title' => 'Example',
   'href'  => '#',
 });
 $link->class('important');
 print $link->render();

=head1 DESCRIPTION

The Link class represents a Bootstrap link. The basic link looks like any other
HTML href anchor, but can be extended with a class, role, or adding a dropdown.
This class is used by L<Whatbot::Helper::Bootstrap> to render the top navbar.

=head1 PUBLIC ACCESSORS

=over 4

=item title

The title or label of the link.

=item href

The href attribute of the anchor tag.

=item class

The class attribute, as a string.

=item role

The role attribute, as a string.

=item dropdown_items

An ArrayRef of Link objects. If one is added, the link will render with a
dropdown menu.

=back

=head1 PUBLIC METHODS

=over 4

=item add_dropdown_item( $link_object )

Add a dropdown item to the dropdown_items arrayref. Must be a Link.

=item has_dropdown_items()

Return true if dropdown items exist in the dropdown_items arrayref.

=cut

class Whatbot::Helper::Bootstrap::Link {
	use URI::Encode ();

	has title => (
		'is'  => 'rw',
		'isa' => 'Str',
	);

	has href => (
		'is'  => 'rw',
		'isa' => 'Str',
	);

	has class => (
		'is'  => 'rw',
		'isa' => 'Str',
	);

	has role => (
		'is'  => 'rw',
		'isa' => 'Str',
	);

	has dropdown_as_li => (
		'is'  => 'rw',
		'isa' => 'Bool',
	);

	has dropdown_items => (
		'is'      => 'ro',
		'isa'     => 'ArrayRef[Whatbot::Helper::Bootstrap::Link]',
		'traits'  => [ 'Array' ],
		'default' => sub { [] },
		'handles' => {
			'add_dropdown_item'  => 'push',
			'has_dropdown_items' => 'count',
		},
	);

=item render()

Render the link as a string, with the current set of attributes.

=cut

	method render() {
		my $has_dropdown_items = $self->has_dropdown_items;
		if ( $has_dropdown_items and ( not $self->class or $self->class !~ /dropdown-toggle/ ) ) {
			$self->class( ( $self->class ? $self->class . ' ' : '' ) . 'dropdown-toggle' );
		}
		my $link = sprintf(
			'<a href="%s"%s%s%s>%s%s</a>',
			URI::Encode::uri_encode( $self->href or '' ),
			( $self->class ? ' class="' . $self->class . '"' : '' ),
			( $self->role ? ' role="' . $self->role . '"' : '' ),
			( $has_dropdown_items ? ' data-toggle="dropdown" id="dropdown-' . $self->_title_as_id() . '"' : '' ),
			( $self->title or '' ),
			( $has_dropdown_items ? ' <span class="caret"></span>' : '' ),
		);
		if ( $has_dropdown_items ) {
			my $tag = ( $self->dropdown_as_li ? 'li' : 'div' );
			return sprintf(
				'<%s class="dropdown">%s%s</%s>',
				$tag,
				$link,
				$self->_render_dropdown_menu(),
				$tag,
			);
		}
		return $link;
	}

	method _title_as_id() {
		my $id = $self->title;
		$id =~ s/[^A-Za-z0-9\-_]//g;
		return lc($id);
	}

	method _render_dropdown_menu() {
		my @li = map {
			my $nil = $_->role('menuitem');
			'<li role="presentation">' . $_->render() . '</li>'
		} @{ $self->dropdown_items };
		return '<ul class="dropdown-menu" role="menu" aria-labelledby="dropdown-' . $self->_title_as_id() . '">'
		     . join( "\n", @li )
		     . '</ul>';
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
