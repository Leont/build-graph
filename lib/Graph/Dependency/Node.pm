package Graph::Dependency::Node;
use Any::Moose;
use List::MoreUtils qw//;

use Graph::Dependency;

has graph => (
	is => 'ro',
	isa => 'Graph::Dependency',
	required => 1,
	weak_ref => 1,
);

has phony => (
	is => 'ro',
	isa => 'Bool',
	required => 1,
);

has _dependencies => (
	isa => 'HashRef[Str]',
	default => sub { {} },
	init_arg => 'dependencies',
	traits => ['Hash'],
	handles => {
		all_dependencies  => 'keys',
		_dependencies_types => 'values',
		_kv_dependencies  => 'kv',
		has_dependencies  => 'count',
		get_dependency    => 'get',
		set_dependency    => 'set',
		delete_dependency => 'delete',
		_flat_dependencies => 'elements',
	},
);

sub dependency_types {
	my $self = shift;
	return List::MoreUtils::uniq($self->_dependency_types);
}

sub dependencies_for_type {
	my ($self, $wanted_type) = @_;
	my @ret;
	for my $pair ($self->_kv_dependencies) {
		my ($name, $type) = @{$pair};
		push @ret, $name if $type eq $wanted_type;
	}
	return @ret;
}

has action => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has arguments => (
	isa => 'HashRef',
	traits => ['Hash'],
	handles => {
		get_argument  => 'get',
		set_argument  => 'set',
		has_arguments => 'count',
		_arguments    => 'elements',
	},
	default => sub { {} },
);

sub compile {
	my ($self, $name, $compiling) = @_;

	return $compiling->get_compiled($self) if defined $compiling->get_compiled($self);
	my $optype = 'Graph::Dependency::OP::' . ($self->phony ? 'Phony' : 'File');
	my ($action, $message) = $self->graph->action_for($self->action)->compile($self);
	my @dependencies = map { $self->graph->get_node($_)->compile($_, $compiling) } $self->all_dependencies;
	return $optype->new(filename => $name, dependencies => \@dependencies, action => $action, message => $message);
}

sub to_hashref {
	my $self = shift;
	return {
		name => $self->name,
		phony => $self->phony,
		dependencies => { $self->_flat_dependencies },
		action => $self->action,
		arguments => { $self->_arguments },
	};
}

1;

=attr graph

=attr phony

=attr dependencies

=attr action

=attr arguments

=method compile

=method to_hashref
