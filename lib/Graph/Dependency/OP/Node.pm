package Graph::Dependency::OP::Node;
use Any::Moose 'Role';

has dependencies => (
	isa => 'ArrayRef[Graph::Dependency::OP::Node]',
	default => sub { [] },
	handles => {
		dependencies => 'elements',
	},
);

has action => (
	is => 'ro',
	isa => 'Graph::Dependency::OP::Action',
	required => 1,
);

has arguments => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {} },
);

has verbose_message => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

requires 'outdated';

sub update_self {
	my ($self, $runstate) = @_;
	for my $dep ($self->dependencies) {
		$dep->update_self($runstate);
	}
	if ($self->outdated($runstate)) {
		$runstate->log($self->verbose_message, 1);
		$self->action->execute($self->arguments, $runstate);
	}
	return;
}

1;

=method dependencies

=attr action

=attr arguments

=attr verbose_message

=method outdated

=method update_self
