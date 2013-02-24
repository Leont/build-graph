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
	isa => 'ArrayRef',
	required => 1,
);

1;

#ABSTRACT: Runtime information for actions

