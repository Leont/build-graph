package Build::Graph::Variable::Free;

use strict;
use warnings;

use base 'Build::Graph::Role::Variable';

sub add_entries {
	my ($self, @entries) = @_;
	push @{ $self->{entries} }, @entries;
	$self->pass_on($_) for @entries;
	return;
}

1;
