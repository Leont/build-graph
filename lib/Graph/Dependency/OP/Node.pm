package Graph::Dependency::OP::Node;
use Any::Moose 'Role';

use Graph::Dependency::OP::Action::Sub;

has name => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

has dependencies => (
	isa => 'ArrayRef[Graph::Dependency::OP::Node]',
	traits => ['Array'],
	default => sub { [] },
	handles => {
		dependencies => 'elements',
	},
);

has action => (
	is => 'ro',
	isa => 'Graph::Dependency::OP::Action',
	coerce => 1,
	required => 1,
);

has message => (
	is => 'ro',
	isa => 'Str|Undef',
	required => 1,
);

requires 'outdated';

sub update_self {
	my ($self, $runstate) = @_;
	for my $dep ($self->dependencies) {
		$dep->update_self($runstate);
	}
	if ($self->outdated($runstate)) {
		$runstate->log($self->message, 0) if defined $self->message;
		$self->action->execute($runstate);
	}
	return;
}

1;

__END__

=attr name

Name of the node

=method dependencies

The list of Node objects that are dependencies of this node.

=attr action

The name of the action that may be triggered by this node.

=attr message

The message that this action may output or log when the action is being run.

=method outdated

Returns true if the node is not up-to-date.

=method update_self

Update the node.
