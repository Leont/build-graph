package Graph::Dependency::OP::Node::File;
use Any::Moose;
use List::MoreUtils 'any';

with 'Graph::Dependency::OP::Node';

has filename => (
	is => 'ro',
	isa => 'Str',
	lazy => 1,
	builder => 'name',
);

sub outdated {
	my ($self, $run) = @_;
	return 1 if not -e $self->filename;
	return 1 if any { $run->compare($self, $_) > 0 } grep { $_->can('filename') } $self->dependencies;
	return 0;
}

1;

__END__

=attr filename

The name of the file

=method outdated($run)

Returns true if the current file less recent than any of its dependencies.

