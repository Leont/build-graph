package Build::Graph::Role::Plugin;

use strict;
use warnings;

sub get_command;
sub get_transformation;

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name    => $args{name} || ($class =~ / \A (?:.*::)? ([^:]+) \z /xms)[0]
	}, $class;
	return $self;
}

sub name {
	my $self = shift;
	return $self->{name};
}

sub to_hashref {
	my $self = shift;
	return {
		module => ref($self),
	};
}

1;





# ABSTRACT: A base role for various types of plugins
