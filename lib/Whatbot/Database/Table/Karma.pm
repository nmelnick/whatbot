###########################################################################
# Karma.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use Moops;

=head1 NAME

Whatbot::Database::Table::Karma - Database functionality for karma.

=head1 SYNOPSIS

 # In whatbot
 $self->model('Karma')->increment( 'whatbot, 'awesome_user' );

 # Outside whatbot
 use Whatbot::Database::Table::Karma;
 my $model = Whatbot::Database::Table::Karma->new();
 $model->increment( 'whatbot', 'awesome_user' );

=head1 DESCRIPTION

Whatbot::Database::Table::Karma provides database functionality for karma.

=head1 METHODS

=over 4

=cut

class Whatbot::Database::Table::Karma extends Whatbot::Database::Table {
  method BUILD(...) {
    $self->init_table({
      'name'        => 'karma',
      'primary_key' => 'karma_id',
      'indexed'     => [ 'subject', 'user' ],
      'defaults'    => {
        'created'   => { 'database' => 'now' }
      },
      'columns'     => {
        'karma_id' => {
          'type'  => 'serial'
        },
        'subject' => {
          'type'  => 'varchar',
          'size'  => 255
        },
        'user' => {
          'type'  => 'varchar',
          'size'  => 255
        },
        'created' => {
          'type'  => 'integer'
        },
        'amount' => {
          'type'  => 'integer'
        }
      }
    });
  }

  method _top_bottom_n( Str $user, Num $n, Bool $istop? ) {
    my $query = "
      SELECT subject, sum FROM (
        SELECT subject, sum(amount) AS sum FROM karma WHERE user LIKE '$user'
        GROUP BY subject
        )
       ORDER BY sum " . ($istop ? "desc" : "asc") . "
       LIMIT $n";
    
    my $sth = $self->database->handle->prepare($query);
    $sth->execute();
    return $sth->fetchall_arrayref({});
  }

  sub top_n {
    return _top_bottom_n(@_, 1);
  }

  sub bottom_n {
    return _top_bottom_n(@_, 0);
  }

=item decrement( $topic, $user )

Decrement the karma on a topic.

=cut

  method decrement( Str $topic!, Str $user! ) {
    $self->create({
      'subject'   => $topic,
      'user'      => $user,
      'amount'    => -1
    });
  }

=item increment( $topic, $user )

Increment the karma on a topic.

=cut

  method increment( Str $topic!, Str $user! ) {
    $self->create({
      'subject'   => $topic,
      'user'      => $user,
      'amount'    => 1
    });
  }

=item get( $topic )

Retrieve the karma on a topic.

=cut

  method get( Str $topic! ) {
    my $row = $self->search_one({
      '_select' => 'SUM(amount)',
      'subject' => lc($topic)
    });
    return ( $row ? $row->column_data->[0] : '' );
  }

=item get_extended( $topic )

Retrieve extended info on a topic's karma. Returns a hashref containing
'Increments', which is the total volume of increments, 'Decrements',
containing the total volume of decrements, and 'Last', which is an arrayref
containing the last changing user and the amount of karma given.

=cut

  method get_extended( Str $topic! ) {
    my $increment_row = $self->search_one({
      '_select' => 'COUNT(amount)',
      'subject' => $topic,
      'amount'  => 1
    });
    my $decrement_row = $self->search_one({
      '_select' => 'COUNT(amount)',
      'subject' => $topic,
      'amount'  => -1
    });
    my $last_row = $self->search_one({
      'subject'   => $topic,
      '_order_by' => 'karma_id DESC',
      '_limit'    => 1
    });
    
    return $last_row ? {
      'Increments' => $increment_row->column_data->[0],
      'Decrements' => $decrement_row->column_data->[0],
      'Last'       => [
        $last_row->user,
        $last_row->amount
      ]
    } : undef;
  }
}

1;

=pod

=back

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
