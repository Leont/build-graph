package Build::Graph::PluginSet;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		groups => $args{groups},
	}, $class;
}

sub get_command {
	my ($self, $key) = @_;
	my ($groupname, $command) = split m{/}, $key, 2;
	my $group = $self->{groups}{$groupname};
	return $group && $group->can('lookup_command') ? $group->lookup_command($command) : ();
}

sub add_plugin {
	my ($self, $name, $group) = @_;
	$self->{groups}{$name} = $group;
	return;
}

sub to_hashref {
	my $self = shift;
	my %ret;
	for my $name (keys %{ $self->{groups} }) {
		$ret{$name} = $self->{groups}{$name}->serialize;
	}
	return \%ret;
}

1;

#ABSTRACT: The set of commands used in a build graph

