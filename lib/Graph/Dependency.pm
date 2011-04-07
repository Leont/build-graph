package Graph::Dependency;
use Any::Moose;
use Carp ();

has nodes => (
	is => 'ro',
	isa => 'HashRef[Graph::Dependency::Node]',
	required => 1,
	handles => {
		get_node => 'get',
	},
);

has runner => (
	is => 'ro',
	isa => 'Str',
	default => 'Graph::Dependency::Run',
);

sub run {
	my ($self, $start, %args) = @_;
	my $node = $self->get_node($start) or Carp::croak("No such node '$start' in graph");
	my $run = $self->runner->new(%args);
	return $node->update_self($run);
}

1;

# ABSTRACT: Barebones dependency graphs
