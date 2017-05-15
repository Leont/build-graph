package Build::Graph::Role::CommandSet;

use strict;
use warnings;
use Scalar::Util ();

sub get_command;
sub get_transformation;

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name    => $args{name} || ($class =~ / \A (?:.*::)? ([^:]+) \z /xms)[0],
		graph   => $args{graph},
	}, $class;
	Scalar::Util::weaken($self->{graph});
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

# ABSTRACT: A base role for Sets of action and substitution commands




# ABSTRACT: A base role for various types of plugins
