package Graph::Dependency::Node::File;
use Any::Moose;

with 'Graph::Dependency::Node';

has filename => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

sub outdated {
	my ($self, $run) = @_;
	return $run->file_comperator->($self, $self->dependencies);
}

1;
