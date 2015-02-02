package Build::Graph::Role::CommandProvider;

use Moo::Role;

with 'Build::Graph::Role::Dependent';

requires 'configure_commands';

sub dependencies {
	my $self = shift;
	return ref $self;
}

1;

# ABSTRACT: A role for adding commands to a graph