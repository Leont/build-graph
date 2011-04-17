package Graph::Dependency::OP::Action::Sub;
use Any::Moose;

has callback => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1,
	handles => {
		execute => 'execute',
	},
);

with 'Graph::Dependency::OP::Action';

1;

__END__

=attr callback

The callback to run when the action is run.
