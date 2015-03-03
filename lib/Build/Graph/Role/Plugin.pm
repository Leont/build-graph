package Build::Graph::Role::Plugin;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless {
		name     => $args{name} || Carp::croak('No name given'),
		commands => $class->_get_commands(%args),
		substs   => $class->_get_substs(%args),
	}, $class;
}

sub name {
	my $self = shift;
	return $self->{name};
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

sub _get_commands {
	return {};
}

sub _get_substs {
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
