package Graph::Dependency::OP;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';
use Carp ();
use Graph::Dependency::OP::Run;

subtype 'Graph::Dependency::Op::Node' => as role_type('Graph::Dependency::OP::Node');

has nodes => (
	isa => 'HashRef[Graph::Dependency::OP::Node]',
	traits => ['Hash'],
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

=method get_node($key)

Get the node named C<$key>.

=attr runner

A classname that is used to run the OP-tree. Defaults to C<Graph::Dependency::OP::Run>.

=method run($start, %args)

Run the current optree, optionally with extra arguments.
