package Build::Graph::Role::Plugin;

use strict;
use warnings;

use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name  => $args{name}  || Carp::croak('No name given'),
		graph => $args{graph} || Carp::croak('No graph given'),
	}, $class;
	Scalar::Util::weaken($self->{graph});
	return $self;
}

sub name {
	my $self = shift;
	return $self->{name};
}

sub graph {
	my $self = shift;
	return $self->{graph};
}

sub lookup_command {
	my ($self, $name, $plugins) = @_;
	return $self->get_commands->{$name};
}

sub lookup_subst {
	my ($self, $name) = @_;
	return $self->get_substs->{$name};
}

sub get_commands {
	return {};
}

sub get_substs {
	return {};
}

sub serialize {
	my $self = shift;
	return {
		module => ref($self),
		name   => $self->{name},
	};
}

1;

# ABSTRACT: A base role for various types of plugins
