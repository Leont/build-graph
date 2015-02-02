package Build::Graph::Role::CommandProvider;

use strict;
use warnings;

use parent 'Build::Graph::Role::Dependent';

sub configure_commands;

sub dependencies {
	my $self = shift;
	return ref $self;
}

1;

# ABSTRACT: A role for adding commands to a graph
