package Build::Graph::CommandSet;
use Moo;

has _commands => (
	is       => 'ro',
	init_arg => undef,
	default  => sub { {} },
);

sub get {
	my ($self, $key) = @_;
	return $self->_commands->{$key};
}

sub add {
	my ($self, $key, $value) = @_;
	$self->_commands->{$key} = $value;
	return;
}

1;

#ABSTRACT: The set of commands used in a build graph

