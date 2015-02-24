package Build::Graph::Role::CommandProvider;

use strict;
use warnings;

sub new {
	my ($class, @args) = @_;
	return bless {
		commands => { $class->_get_commands(@args) },
	}, $class;
}

sub dependencies {
	my $self = shift;
	return ref $self || $self;
}

sub serialize {
	my $self = shift;
	return { module => ref($self) || $self };
}

sub lookup_command {
	my ($self, $name) = @_;
	return $self->{commands}{$name};
}

sub _get_commands;

1;

# ABSTRACT: A role for adding commands to a graph
