package Build::Graph::Info;
use Any::Moose;

has name => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has arguments => (
	is => 'ro',
	isa => 'Any',
	required => 1,
);

has dependencies => (
	is => 'ro',
	isa => 'Build::Graph::Dependencies',
	required => 1,
);

1;
