package Build::Graph::Info;
use Moo;

has name => (
	is       => 'ro',
	required => 1,
);

has arguments => (
	is => 'ro',
	required => 1,
);

has dependencies => (
	is => 'ro',
	required => 1,
);

1;

#ABSTRACT: Runtime information for actions

