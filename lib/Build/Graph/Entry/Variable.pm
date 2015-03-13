package Build::Graph::Entry::Variable;

use strict;
use warnings;

use parent 'Build::Graph::Role::Entries';

sub add_entries {
	my ($self, @entries) = @_;
	push @{ $self->{entries} }, @entries;
	return;
}

1;
