package Build::Graph::Node;
use Any::Moose;

use Build::Graph::Dependencies;

has phony => (
	is       => 'ro',
	isa      => 'Bool',
	required => 1,
);

has dependencies => (
	is      => 'ro',
	isa     => 'Build::Graph::Dependencies',
	coerce  => 1,
	default => sub { Build::Graph::Dependencies->new },
);

has action => (
	is       => 'rw',
	isa      => 'Str',
	required => 1,
);

has arguments => (
	isa     => 'HashRef',
	traits  => ['Hash'],
	handles => {
		get_argument  => 'get',
		set_argument  => 'set',
		has_arguments => 'count',
		_arguments    => 'elements',
	},
	default => sub { {} },
);

sub to_hashref {
	my $self = shift;
	return {
		phony        => $self->phony,
		dependencies => $self->dependencies->to_hashref,
		action       => $self->action,
		arguments    => { $self->_arguments },
	};
}

1;

#ABSTRACT: A dependency graph node

__END__

=attr phony

=attr dependencies

=attr action

=attr arguments

=method to_hashref
