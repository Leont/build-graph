package Build::Graph::CommandSet;

use strict;
use warnings;

use Carp ();

use Build::Graph::Group;

sub new {
	my $class = shift;

	my %args = @_ == 1 ? %{ $_[0] } : @_;
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
	return $group->get($command) if $group;
	return;
}

sub add {
	my ($self, $name, %args) = @_;
	$args{elements} = delete $args{commands};
	my $command = Build::Graph::Group->new(%args);
	$self->{groups}{$name} = $command;
	return;
}

sub load {
	my ($self, $provider, @args) = @_;
	$self->loader->load($provider, @args)->configure_commands($self, @args);
	return;
}

sub all_for_group {
	my ($self, $groupname) = @_;
	return $self->{groups}{$groupname}->all;
}

sub to_hashref {
	my $self = shift;
	my %ret;
	for my $name (keys %{ $self->{groups} }) {
		my $group = $self->{groups}{$name};
		$ret{$name} = { module => $group->module };
	}
	return \%ret;
}

1;

#ABSTRACT: The set of commands used in a build graph

