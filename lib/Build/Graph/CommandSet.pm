package Build::Graph::CommandSet;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		groups => $args{groups},
		loader => $args{loader} || Carp::croak('No loader given'),
	}, $class;
}

sub loader {
	my $self = shift;
	return $self->{loader};
}

sub get {
	my ($self, $key) = @_;
	my ($groupname, $command) = split m{/}, $key, 2;
	my $group = $self->{groups}{$groupname};
	return $group ? $group->{commands}{$command} : ();
}

sub add {
	my ($self, $name, %args) = @_;
	%{ $self->{groups}{$name} } = %args;
	return;
}

sub load {
	my ($self, $provider, @args) = @_;
	$self->loader->load($provider, @args)->configure_commands($self, @args);
	return;
}

sub all_for_group {
	my ($self, $groupname) = @_;
	return keys %{ $self->{groups}{$groupname}{commands} };
}

sub to_hashref {
	my $self = shift;
	my %ret;
	for my $name (keys %{ $self->{groups} }) {
		$ret{$name} = { module => $self->{groups}{$name}{module} };
	}
	return \%ret;
}

1;

#ABSTRACT: The set of commands used in a build graph

