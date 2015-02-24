package Build::Graph::Role::CommandProvider;

use strict;
use warnings;

use parent 'Build::Graph::Role::Plugin';

sub new {
	my ($class, @args) = @_;
	my $ret = $class->SUPER::new(@args);
	$ret->{commands} = { $class->_get_commands(@args) };
	return $ret;
}

sub lookup_command {
	my ($self, $name) = @_;
	return $self->{commands}{$name};
}

sub _get_commands;

1;

# ABSTRACT: A role for adding commands to a graph
