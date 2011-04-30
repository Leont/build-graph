package Graph::Dependency::Action::Sub;
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

with 'Graph::Dependency::Action';

1;

__END__

=attr callback

The callback to run when the action is run.