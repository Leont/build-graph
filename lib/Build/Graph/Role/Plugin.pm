package Build::Graph::Role::Plugin;

use strict;
use warnings;

use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name     => $args{name}  || Carp::croak('No name given'),
		graph    => $args{graph} || Carp::croak('No graph given'),
	}, $class;
	$self->{commands} = $self->_get_commands(%args);
	$self->{substs}   = $self->_get_substs(%args);
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
