package Build::Graph::Role::Loader;

use Moo::Role;

requires 'load';

has graph => (
	is       => 'ro',
	required => 1,
);

sub to_hashref {
	my $self = shift;
	return {
		module => ref($self),
	};
}

1;

