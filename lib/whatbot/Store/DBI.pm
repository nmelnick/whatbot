###########################################################################
# whatbot/Store/DBI.pm
###########################################################################
# Base class for DBI Storage
###########################################################################
# the whatbot project - http://www.whatbot.org
###########################################################################

package whatbot::Store::DBI;
use Moose;
extends 'whatbot::Store';
use DBI;

has 'connectArray' => (
	is	=> 'rw',
	isa	=> 'ArrayRef'
);

sub connect {
	my ($self) = @_;
	
	die "ERROR: No connect string offered by store module" if (!$self->connectArray);
	my $dbh = DBI->connect(@{$self->connectArray}) or die DBI::errstr;
	$self->handle($dbh);
}

sub store {
	my ($self, $table, $assignRef) = @_;
	
	return undef if (!$table or $table =~ /[`'" ;]/);
	return undef if (!$assignRef or ref($assignRef) ne 'HASH' or scalar(keys %{$assignRef}) == 0);
	
	my $columns;
	my $values;
	foreach my $column (keys %$assignRef) {
		$columns .= ", " if ($columns);
		$columns .= $column;
		$values .= ", " if ($values);
		$values .= $self->handle->quote($assignRef->{$column});
	}
	my $query = $self->handle->do(qq{
		INSERT INTO $table
		 ($columns)
		VALUES
		 ($values)
	}) or warn DBI::errstr;
	
	return 1;
}

sub retrieve {
	my ($self, $table, $columnRef, $queryRef, $orderBy, $numberItems) = @_;
	
	return undef if (!$table or $table =~ /[`'" ;]/);
	
	my $columns = "*";
	my $where = "";
	my $limit = "";
	my $order = "";
	
	if (defined $columnRef and scalar(@$columnRef) > 0) {
		$columns = join(", ", @$columnRef);
	}
	if (defined $queryRef and scalar(keys %{$queryRef}) > 0) {
		$where = "WHERE ";
		foreach my $column (keys %$queryRef) {
			$where .= " AND " if ($where ne "WHERE ");
			if ($queryRef->{$column} =~ /^LIKE /) {
				$queryRef->{$column} =~ s/^LIKE //;
				$where .= $column . " LIKE " . $self->handle->quote($queryRef->{$column});
			} else {
				$where .= $column . " = " . $self->handle->quote($queryRef->{$column});
			}
		}
	}
	if (defined $numberItems and $numberItems > 0) {
		$limit = "LIMIT $numberItems";
	}
	if (defined $orderBy) {
		$order = "ORDER BY " . $orderBy;
	}
	
	my @results;
	my $queryText = qq{
		SELECT $columns
		  FROM $table
		 $where
		 $order
		 $limit
	};
	my $query = $self->handle->prepare($queryText);
	$query->execute() or warn DBI::errstr;
	while (my $result = $query->fetchrow_hashref()) {
		push(@results, $result);
	}
	
	return \@results;
}

sub delete {
	my ($self, $table, $queryRef) = @_;
	
	return undef if (!$table or $table =~ /[`'" ;]/);
	return undef if (!$queryRef or ref($queryRef) ne 'HASH' or scalar(keys %{$queryRef}) == 0);
	
	my $where = "";
	foreach my $column (keys %$queryRef) {
		$where .= " AND " if ($where ne "");
		$where .= $column . " = " . $self->handle->quote($queryRef->{$column});
	}
	my $query = $self->handle->prepare(qq{
		DELETE FROM $table
		WHERE $where
	});
	$query->execute() or warn DBI::errstr;
	
	return 1;
}

sub update {
	my ($self, $table, $assignRef, $queryRef) = @_;
	
	return undef if (!$table or $table =~ /[`'" ;]/);
	return undef if (!$assignRef or ref($assignRef) ne 'HASH' or scalar(keys %{$assignRef}) == 0);
	
	my $set = "";
	foreach my $column (keys %$assignRef) {
		$set .= ", " if ($set ne "");
		$set .= $column . " = " . $self->handle->quote($assignRef->{$column});
	}
	my $where = "";
	foreach my $column (keys %$queryRef) {
		$where .= " AND " if ($where ne "");
		$where .= $column . " = " . $self->handle->quote($queryRef->{$column});
	}
	my $query = $self->handle->prepare(qq{
		UPDATE $table
		   SET $set
		 WHERE $where
	});
	$query->execute() or warn DBI::errstr;
	
	return 1;
}

1;
