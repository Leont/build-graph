package Graph::Dependency::Action::Sub;
use Any::Moose;

has callback => (
	is => 'ro',
	isa => 'CodeRef',
	required => 1,
	handles => {
		execute => 'execute',
	},
);

with 'Graph::Dependency::Action';

1;
