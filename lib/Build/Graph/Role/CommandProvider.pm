package Build::Graph::Role::CommandProvider;

use strict;
use warnings;

use parent 'Build::Graph::Role::Plugin';

sub new {
	my ($class, @args) = @_;
	my $ret = $class->SUPER::new(@args);
	$ret->{commands} = $class->_get_commands(@args);
	$ret->{substs}   = $class->_get_substs(@args);
	return $ret;
}

sub lookup_command {
	my ($self, $name, $plugins) = @_;
	my $raw = $self->{commands}{$name};
	if (ref($raw) eq 'ARRAY') {
		my @commands = map { $plugins->get_command($_) } @{$raw};
		return sub { $_->(@_) for @commands };
	}
	return $raw;
}

sub lookup_subst {
	my ($self, $name) = @_;
	return $self->{substs}{$name};
}

sub _get_commands;

sub _get_substs {
	return {};
}

1;

# ABSTRACT: A role for adding commands to a graph
