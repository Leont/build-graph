package Graph::Dependency::Compiling;

use Any::Moose;

has compiled => (
	isa => 'HashRef[Graph::Dependency::OP::Node]',
	traits => ['Hash'],
	init_arg => undef,
	default => sub { {} },
	handles => {
		get_compiled => 'get',
		add_compiled => 'set',
		all_compiled => 'kv',
	},
);

1;
