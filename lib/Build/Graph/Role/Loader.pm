package Build::Graph::Role::Loader;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless {
		graph => $args{graph} || Carp::croak(''),
	}, $class;
}

sub graph {
	my $self = shift;
	return $self->{graph};
}

sub to_hashref {
	my $self = shift;
	return {
		module => ref($self),
	};
}

1;

