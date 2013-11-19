package Build::Graph::Group;
use Moo;

has module => (
	is       => 'ro',
	required => 1,
);

has _elements => (
	is       => 'ro',
	init_arg => 'elements',
	default  => sub { {} },
);

sub get {
	my ($self, $command) = @_;
	return $self->_elements->{$command};
}

sub add {
	my ($self, %elements) = @_;
	while (my ($key, $action) = each %elements) {
		$self->_elements->{$key} = $action;
	}
	return;
}

sub all {
	my $self = shift;
	return keys %{ $self->_elements };
}

1;
