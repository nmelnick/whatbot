###########################################################################
# URL.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Database::Table::URL - Database model for url

=head1 SYNOPSIS

 use Whatbot::Database::Table::URL;

=head1 DESCRIPTION

Whatbot::Database::Table::URL does stuff.

=head1 METHODS

=over 4

=cut

class Whatbot::Database::Table::URL extends Whatbot::Database::Table {
	use Image::Size qw(imgsize);
	use Mojo::DOM;
	use URI;
	use Encode qw(encode decode);
	use AnyEvent::HTTP::LWP::UserAgent;

	has 'table_protocol' => ( is => 'rw', isa => 'Whatbot::Database::Table' );
	has 'table_domain'   => ( is => 'rw', isa => 'Whatbot::Database::Table' );
	has 'agent'          => ( is => 'ro', isa => 'Any', default => sub {
		my $ua = AnyEvent::HTTP::LWP::UserAgent->new(
			'agent'    => sprintf( 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Whatbot/%s Chrome/53.0.2785.89 Safari/537.36', $Whatbot::VERSION ),
			'ssl_opts' => { verify_hostname => 0 },
			'timeout'  => 10,
			'maxsize'  => 5192,
		);
		$ua->default_header( 'Referer' => undef );
		return $ua;
	});

	method BUILD (...) {
		$self->init_table({
			'name'        => 'url',
			'primary_key' => 'url_id',
			'defaults'    => {
				'timestamp' => { 'database' => 'now' }
			},
			'columns'     => {
				'url_id' => {
					'type'  => 'serial'
				},
				'timestamp' => {
					'type'  => 'integer'
				},
				'protocol_id' => {
					'type'  => 'integer'
				},
				'domain_id' => {
					'type'  => 'integer'
				},
				'path' => {
					'type'  => 'varchar',
					'size'  => 255
				},
				'user' => {
					'type'  => 'varchar',
					'size'  => 255
				},
				'title' => {
					'type'  => 'varchar',
					'size'  => 512
				}
			}
		});
		my $protocol = Whatbot::Database::Table->new();
		$protocol->init_table({
			'name'        => 'url_protocol',
			'primary_key' => 'protocol_id',
			'indexed'     => ['name'],
			'columns'     => {
				'protocol_id' => {
					'type'  => 'serial'
				},
				'name'    => {
					'type'  => 'varchar',
					'size'  => 12
				},
			}
		});
		$self->table_protocol($protocol);
		my $domain = Whatbot::Database::Table->new();
		$domain->init_table({
			'name'        => 'url_domain',
			'primary_key' => 'domain_id',
			'indexed'     => ['name'],
			'defaults'    => {
				'timestamp' => { 'database' => 'now' }
			},
			'columns'     => {
				'domain_id' => {
					'type'  => 'serial'
				},
				'timestamp' => {
					'type'  => 'integer'
				},
				'name'    => {
					'type'  => 'varchar',
					'size'  => 255
				},
			}
		});

		if ( my $config = $self->config->{'commands'}->{'url'}->{'basic_auth'} ) {
		 	foreach my $entry (@$config) {
				$self->agent->credentials(
					$entry->{'domain'},
					$entry->{'realm'},
					$entry->{'user'},
					$entry->{'password'},
				);
			}
		}

		$self->table_domain($domain);
	}

=item get_protocol($protocol)

Retrieve, or create and retrieve, the given protocol's id.

=cut

	method get_protocol( Str $protocol ) {
		my $protocol_row = $self->table_protocol->search_one({
			'name' => $protocol
		});
		unless ($protocol_row) {
			$protocol_row = $self->table_protocol->create({
				'name' => $protocol
			});
		}

		return $protocol_row->protocol_id;
	}

=item get_domain($domain)

Retrieve, or create and retrieve, the given domain's id.

=cut

	method get_domain( Str $domain ) {
		my $domain_row = $self->table_domain->search_one({
			'name' => $domain
		});
		unless ($domain_row) {
			$domain_row = $self->table_domain->create({
				'name' => $domain
			});
		}

		return $domain_row->domain_id;
	}

=item url_async($url, $from, $callback)

Retrieve, or create and retrieve, the given URL. Callback accepts a $row.

=cut

	method url_async( Str $url, Str $from, $callback ) {
		my $uri = URI->new($url);
		my $protocol_id = $self->get_protocol( $uri->scheme );
		my $domain_id = $self->get_domain( $uri->host );

		# Check if exists
		my $row = $self->search_one({
			'protocol_id' => $protocol_id,
			'domain_id'   => $domain_id,
			'path'        => $uri->path,
		});
		if ($row) {
			$callback->($row);
		} else {
			$self->retrieve_url_async(
				$url,
				sub {
					my ($title) = @_;
					$callback->( $self->create({
						'user'        => $from,
						'title'       => $title,
						'domain_id'   => $domain_id,
						'protocol_id' => $protocol_id,
						'path'        => $uri->path . ( $uri->query ? '?' . $uri->query : '' )
					}) );
				}
			);
		}
		return;
	}

=item url_title_async($url, $from, $callback)

Retrieve, or create and retrieve, the given URL, and return the title to the
provided callback.

=cut

	method url_title_async( Str $url, Str $from, $callback ) {
		$self->url_async(
			$url,
			$from,
			sub {
				my ($row) = @_;
				my $title = $row->title;
				if ( $title =~ /^! / ) {
					$row->delete;
				}
				$callback->($title);
			}
		);
		return;
	}

=item retrieve_url_async( $url, $callback )

GET the given URL using LWP.

=cut

	method retrieve_url_async( $url, $callback ) {
		my $title;
		my $response;
		eval {
			$self->agent->get_async($url)->cb(sub {
				my $response = shift->recv;
				if ( $response->code < 400 ) {
					$title = $self->parse_url_content( $url, $response );
				} elsif ( $self->show_failures() ) {
					my $status = $response->code;
					if ( $status == 401 or $status == 403 ) {
						$title = '! Authorization required';
					} elsif ( $status == 404 ) {
						$title = '! Not Found';
					} elsif ( $status == 595 ) {
						$title = '! Could not connect or resolve address';
					} else {
						warn $response->content;
						$title = '! Error ' . $status;
					}
				}
				$callback->($title);
			});
		};
		if ($@) {
			$callback->('! Unable to retrieve (' . $url . ' - ' . $self->agent->status . ' ' . $self->agent->content . ')');
		}
		return;
	}

	method parse_url_content( $url, $response ) {
		my $content = $response->content;
		my $title = 'No parsable title';
		if ( $url =~ /twitter\.com.*status/ ) {
			my $dom = Mojo::DOM->new( charset => 'UTF-8')->parse($content);
			my $tweet_id = ( split( '/', $url ) )[-1];
			my $tweet = $dom->at('[data-tweet-id="' . $tweet_id . '"]');
			$title = '@' . $tweet->attr('data-screen-name') . ': ' . decode( 'UTF-8', $tweet->at(".tweet-text")->all_text );

		} elsif ( $response->header('Content-Type') =~ /^image/ ) {
			my ( $width, $height, $type ) = imgsize(\$content);
			if ($type) {
				$title = $type . ' Image: ' . $width . 'x' . $height;
			}

		} elsif ( $content =~ m/<title[^>]*>(.*?)<\/title>/ ) {
			$title = $1;
		}
		return $title;
	}

	method show_failures() {
		my $config = $self->config->{'commands'}->{'url'};
		if ($config) {
			return if ( $config->{'hide_failures'} );
		}
		return 1;
	}
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
