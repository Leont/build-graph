package Build::Graph::Action;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

coerce 'Build::Graph::Action',
	from 'Str', via {
		return Build::Graph::Action->new(command => $_);
	},
	from 'HashRef', via {
		return Build::Graph::Action->new(%{$_});
	};

has command => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

has arguments => (
	is => 'rw',
	isa => 'Any',
	predicate => 'has_argument',
);

sub to_hashref {
	my $self = shift;
	return {
		command => $self->command,
		arguments => $self->arguments
	};
}

1;
