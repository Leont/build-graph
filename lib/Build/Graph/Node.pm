package Build::Graph::Node;
use Any::Moose;

use Build::Graph::Dependencies;
use Build::Graph::Action;

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

has action   => (
	is       => 'rw',
	isa      => 'Build::Graph::Action',
	coerce   => 1,
	required => 1,
);

sub to_hashref {
	my $self = shift;
	return {
		phony        => $self->phony,
		dependencies => $self->dependencies->to_hashref,
		action       => $self->action->to_hashref,
	};
}

1;

#ABSTRACT: A dependency graph node

__END__

=attr phony

=attr dependencies

=attr action

=method to_hashref
