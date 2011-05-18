package Build::Graph::Action;
use Any::Moose;
use Any::Moose '::Util::TypeConstraints';

my $from_string = sub {
	return Build::Graph::Action->new(command => $_);
};
my $from_hashref = sub {
	return Build::Graph::Action->new(%{$_});
};

coerce 'Build::Graph::Action',
	from 'Str', $from_string;
	from 'HashRef', $from_hashref;

subtype 'Build::Graph::ActionList', as 'ArrayRef[Build::Graph::Action]';
coerce 'Build::Graph::ActionList',
	from 'Build::Graph::Action', via {
		return [ $_ ];
	},
	from 'ArrayRef', via {
		return [ map { ref() ? $from_hashref->() : $from_string->() } @{$_} ]
	},
	from 'HashRef', via {
		return [ $from_hashref->() ];
	},
	from 'Str', via {
		return [ $from_string->() ];
	};

has command => (
	is       => 'rw',
	isa      => 'Str',
	required => 1,
);

has arguments => (
	is        => 'rw',
	isa       => 'Any',
	predicate => 'has_argument',
);

sub to_hashref {
	my $self = shift;
	return {
		command   => $self->command,
		arguments => $self->arguments
	};
}

1;

__END__

=attr command

=attr arguments

=method to_hashref
