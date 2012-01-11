package Build::Graph::CommandSet;
use Any::Moose;

has commands => (
	isa      => 'HashRef[CodeRef]',
	traits   => ['Hash'],
	init_arg => undef,
	default  => sub { {} },
	handles  => {
		all => 'keys',
		get => 'get',
		add => 'set',
	},
);

1;

#ABSTRACT: The set of commands used in a build graph

