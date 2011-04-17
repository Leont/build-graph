package Graph::Dependency::OP;
use Any::Moose;
use Carp ();

has nodes => (
	is => 'ro',
	isa => 'HashRef[Graph::Dependency::OP::Node]',
	required => 1,
	handles => {
		get_node => 'get',
	},
);

has runner => (
	is => 'ro',
	isa => 'Str',
	default => 'Graph::Dependency::OP::Run',
);

sub run {
	my ($self, $start, %args) = @_;
	my $node = $self->get_node($start) or Carp::croak("No such node '$start' in graph");
	my $run = $self->runner->new(%args);
	return $node->update_self($run);
}

1;

# ABSTRACT: Barebones dependency graphs

__END__

=attr nodes

=attr runner

=method run
