package Graph::Dependency::OP::Node::Phony;
use Any::Moose;

with 'Graph::Dependency::OP::Node';

has _ran => (
	is => 'ro',
	traits => ['Hash'],
	isa => 'HashRef[Int]',
	init_arg => undef,
	default => sub { {} },
);

sub outdated {
	my ($self, $run) = @_;
	return not $self->_ran->{$run->id}++;
}

1;

__END__

=method outdated($run)

Returns true the first it is called, and false from then on.

