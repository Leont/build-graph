package Build::Graph::Action;
use Moo;

has command => (
	is       => 'rw',
	required => 1,
);

has arguments => (
	is        => 'rw',
	predicate => 'has_arguments',
);

sub to_hashref {
	my $self = shift;
	return {
		command   => $self->command,
		(arguments => $self->arguments) x!! $self->has_arguments,
	};
}

1;

#ABSTRACT: A Build::Graph action

=attr command

=attr arguments

=method to_hashref
