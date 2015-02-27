package Build::Graph::PluginSet;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		plugins  => $args{plugins} || {},
		matchers => $args{marchers} || {},
	}, $class;
}

sub get_command {
	my ($self, $key) = @_;
	my ($groupname, $command) = split m{/}, $key, 2;
	my $group = $self->{plugins}{$groupname};
	return $group && $group->can('lookup_command') ? $group->lookup_command($command, $self) : ();
}

sub get_subst {
	my ($self, $key) = @_;
	my ($groupname, $subst) = split m{/}, $key, 2;
	my $group = $self->{plugins}{$groupname};
	return $group && $group->can('lookup_subst') ? $group->lookup_subst($subst) : ();
}

sub add_plugin {
	my ($self, $name, $plugin) = @_;
	$self->{plugins}{$name} = $plugin;
	$self->_match_plugin($name, $plugin);
	return;
}

sub to_hashref {
	my $self = shift;
	my @ret;
	for my $plugin (values %{ $self->{plugins} }) {
		push @ret, $plugin->serialize;
	}
	return \@ret;
}

sub add_handler {
	my ($self, $name, $callback) = @_;
	$self->{matchers}{$name} = $callback;
	for my $plugin (values %{ $self->{plugins} }) {
		if ($plugin->isa($name)) {
			$callback->($name, $plugin);
		}
	}
	return;
}

sub _match_plugin {
	my ($self, $name, $plugin) = @_;
	for my $matcher (keys %{ $self->{matchers} }) {
		if ($plugin->isa($matcher)) {
			$self->{matchers}{$matcher}->($name, $plugin);
		}
	}
	return;
}

1;

#ABSTRACT: The set of commands used in a build graph

