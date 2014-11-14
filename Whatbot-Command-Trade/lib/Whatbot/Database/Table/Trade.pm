###########################################################################
# Trade.pm
# the whatbot project - http://www.whatbot.org
###########################################################################

use MooseX::Declare;
use Method::Signatures::Modifiers;

class Whatbot::Database::Table::Trade extends Whatbot::Database::Table {
	has 'trade_fee' => ( is => 'rw', default => '7.00' );
	has 'trade_transaction' => ( is => 'rw', isa => 'Whatbot::Database::Table' );

	method BUILD (...) {     
		$self->init_table({
			'name'        => 'trade',
			'primary_key' => 'trade_id',
			'defaults'    => {
				'timestamp' => { 'database' => 'now' }
			},
			'columns'     => {
				'trade_id' => {
					'type'  => 'integer'
				},
				'user' => {
					'type'  => 'varchar',
					'size'  => 255
				},
				'shares' => {
					'type'  => 'integer'
				},
				'ticker' => {
					'type'  => 'varchar',
					'size'  => 16
				},
				'price' => {
					'type'  => 'double'
				},
				'timestamp' => {
					'type'  => 'integer'
				},
			}
		});
		my $transaction = Whatbot::Database::Table->new();
		$transaction->init_table({
			'name'        => 'trade_transaction',
			'primary_key' => 'trade_transaction_id',
			'columns'     => {
				'trade_transaction_id' => {
					'type'  => 'integer'
				},
				'user' => {
					'type'  => 'varchar',
					'size'  => 255
				},
				'description' => {
					'type'  => 'varchar',
					'size'  => 16
				},
				'amount' => {
					'type'  => 'double'
				},
				'timestamp' => {
					'type'  => 'integer'
				},
			}
		});
		$self->trade_transaction($transaction);
	}

	method trade ( Str $user, Int $shares, Str $ticker, $price ) {
		$ticker = uc($ticker);
		$self->charge_trade_fee($user);
		$self->book( $user, $ticker, ( $price * $shares * -1 ) );
		return $self->create({
			'user'   => $user,
			'shares' => $shares,
			'ticker' => $ticker,
			'price'  => $price,
		});
	}

	method charge_trade_fee ( Str $user ) {
		$self->book(
			$user,
			'Fee',
			( $self->trade_fee * -1 ),
		);
	}

	method book ( Str $user, Str $description, $amount ) {
		return $self->trade_transaction->create({
			'user'        => $user,
			'description' => $description,
			'amount'      => $amount,
		});
	}

	method balance ( Str $user ) {
		my $sth = $self->database->handle->prepare(q{
			SELECT SUM(amount)
			FROM   trade_transaction
			WHERE  user = ?
		});
		$sth->execute($user);
		my ($balance) = $sth->fetchrow_array();
		return ( $balance or 0 );
	}

	method get_share_count ( Str $user, Str $ticker ) {
		$ticker = uc($ticker);
		my $sth = $self->database->handle->prepare(q{
			SELECT SUM(shares)
			FROM   trade
			WHERE  user = ? AND ticker = ?
		});
		$sth->execute( $user, $ticker );
		my ($shares) = $sth->fetchrow_array();
		return ( $shares or 0 );
	}

	method holdings ( Str $user ) {
		my %holdings;
		my $sth = $self->database->handle->prepare(q{
			SELECT ticker, SUM(shares) AS share_count
			FROM   trade
			WHERE  user = ?
			GROUP BY ticker
		});
		$sth->execute($user);
		while ( my $pair = $sth->fetchrow_hashref() ) {
			next if ( $pair->{share_count} == 0 );
			$holdings{ $pair->{ticker} } = $pair->{share_count};
		}
		return \%holdings;
	}
}

1;

=pod

=head1 NAME

Whatbot::Database::Table::Trade - Database model for trade

=head1 LICENSE/COPYRIGHT

Be excellent to each other and party on, dudes.

=cut
