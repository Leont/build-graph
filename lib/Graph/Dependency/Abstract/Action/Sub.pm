package Graph::Dependency::Abstract::Action::Sub;
use Any::Moose;

has callback => (
	is => 'ro',
	isa => 'CodeRef',
	traits => ['Code'],
	required => 1,
	handles => {
		execute => 'execute',
	},
);

with 'Graph::Dependency::Abstract::Action';

1;

__END__

=attr callback

The callback to run when the action is run.
