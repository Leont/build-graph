package Graph::Dependency::Node::Phony;
use Any::Moose;

with 'Graph::Dependency::Node';

has _ran => (
	is => 'ro',
	isa => 'HashRef[Int]',
	init_arg => undef,
	default => sub { {} },
);

sub outdated {
	my ($self, $run) = @_;
	return not $self->_ran->{$run->id}++;
}

1;
