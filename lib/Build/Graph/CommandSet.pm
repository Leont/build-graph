package Build::Graph::CommandSet;
use Moo;

has _commands => (
	is       => 'ro',
	init_arg => 'commands',
	default  => sub { {} },
);

sub get {
	my ($self, $key) = @_;
	return $self->_commands->{$key};
}

1;

#ABSTRACT: The set of commands used in a build graph

