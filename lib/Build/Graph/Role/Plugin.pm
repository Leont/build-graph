package Build::Graph::Role::Plugin;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless {
		name => $args{name} || Carp::croak('No name given'),
	}, $class;
}

sub name {
	my $self = shift;
	return $self->{name};
}

sub serialize {
	my $self = shift;
	return {
		module => ref($self),
		name   => $self->{name},
	};
}

1;
