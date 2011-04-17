package Graph::Dependency::OP::Node::File;
use Any::Moose;

with 'Graph::Dependency::OP::Node';

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

__END__

=attr filename

The name of the file

=method outdated($run)

Returns true if the current file less recent than any of its dependencies.

