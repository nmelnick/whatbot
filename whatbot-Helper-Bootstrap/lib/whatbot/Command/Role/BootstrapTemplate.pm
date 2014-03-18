###########################################################################
# Bootstrap.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

=head1 NAME

whatbot::Helper::Bootstrap - Provide a helper shell to render a Bootstrap page.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 PUBLIC ACCESSORS

=over 4

=item menu_items

An ArrayRef of Link objects that represent the top navbar. These render in
addition to the global application menu dropdown.

=back

=head1 PUBLIC METHODS

=over 4

=item add_menu_item( $link_object )

Add a menu to the menu_items arrayref. Must be a Link.

=item has_menu_items()

Return true if items exist in the menu_items arrayref.

=cut

role whatbot::Command::Role::BootstrapTemplate {
	use whatbot::Helper::Bootstrap;
	use whatbot::Helper::Bootstrap::Link;
	use whatbot::Command::Role::Template;
	use Moose::Util;

	has menu_items => (
		'is'      => 'ro',
		'isa'     => 'ArrayRef[whatbot::Helper::Bootstrap::Link]',
		'traits'  => [ 'Array' ],
		'default' => sub { [] },
		'handles' => {
			'add_menu_item'  => 'push',
			'has_menu_items' => 'count',
		},
	);

	method BUILD(...) {
		# Since we can't extend a role, we're forcing the Template role to be
		# applied to the object that consumes this role.
		Moose::Util::apply_all_roles( $self, 'whatbot::Command::Role::Template', 'whatbot::Command::Role::BootstrapTemplate' );
	}

=item render( $req, \$tt2, \%params? )

Render the given template content, surrounded by the Bootstrap wrapper, to the
response. Requires the request, the tt2 as a string reference, and optionally, a
hashref of parameters to send to the template. Two parameters are reserved for
the wrapper: "page_title" is the name in the upper left, defaulting to
"whatbot", and "error" will render a red box with the content of that variable
in the container.

=cut

	method render( $req, $tt2, $params ) {
		my $new_tt2 = $self->combine_content($tt2);
		# Now, since we didn't extend the Template role, we're calling the 
		# render method manually with $self, instead of using around, since
		# around will whine as the role was not applied until BUILD fired.
		return whatbot::Command::Role::Template::render( $self, $req, $new_tt2, $params );
	}

=item combine_content( $content_tt2 )

Return full renderable template, as a string ref, given the dynamic content TT2
string.

=cut

	method combine_content( $content_tt2 ) {
		my $str = join( "\n", $self->_header_template(), $$content_tt2, $self->_footer_template() );
		return \$str;
	}

	method _header_template() {
		return q~<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1">

	<title>[% page_title || 'whatbot' %]</title>

	<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css">

	<!--[if lt IE 9]>
		<script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
		<script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
	<![endif]-->
	<style type="text/css">
		body { padding-top: 60px; }
		.bg-success {
			padding: 10px 6px;
			margin-bottom: 10px;
		}
	</style>
</head>
<body>
<div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
	<div class="container">
		<div class="navbar-header">
			<button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
				<span class="sr-only">Toggle navigation</span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
				<span class="icon-bar"></span>
			</button>
			<a class="navbar-brand" href="#">[% page_title || 'whatbot' %]</a>
		</div>
		<div class="collapse navbar-collapse">
			<ul class="nav navbar-nav">
			~ . $self->_navbar_template() . q~
			</ul>
		</div><!--/.nav-collapse -->
	</div>
</div>

<div class="container">
[% IF error %]
	<div class="bg-danger">
		[% error %]
	</div>
[% END %]
~;
	}

	method _navbar_template() {
		my @items;

		# Global Menu
		my $applications = whatbot::Helper::Bootstrap::Link->new({
			'title'          => 'Commands',
			'href'           => '#',
			'dropdown_as_li' => 1,
		});
		foreach my $application ( sort { $a cmp $b } @whatbot::Helper::Bootstrap::applications ) {
			$applications->add_dropdown_item(
				whatbot::Helper::Bootstrap::Link->new({
					'title' => $application->[0],
					'href'  => $application->[1],
				})
			);
		}
		unless ( $applications->has_dropdown_items ) {
			$applications->add_dropdown_item(
				whatbot::Helper::Bootstrap::Link->new({
					'title' => 'No commands found',
					'href'  => '#',
					'class' => 'disabled',
				})
			);
		}
		push( @items, $applications->render() );

		# Other items
		if ( $self->has_menu_items ) {
			push( @items, ( map { '<li>' . $_->render() . '</li>' }  @{ $self->menu_items } ) );
		}

		return join( '', @items );
	}

	method _footer_template() {
		return q{</div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
<script src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>
</body>
</html>
};
	}
	
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
