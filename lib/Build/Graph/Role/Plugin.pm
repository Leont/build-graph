package Build::Graph::Role::Plugin;

use strict;
use warnings;

use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name    => $args{name}    || ($class =~ / \A (?:.*::)? ([^:]+) \z /xms)[0],
		graph   => $args{graph}   || Carp::croak('No graph given'),
		counter => $args{counter} || Carp::croak('No counter given'),
	}, $class;
	Scalar::Util::weaken($self->{graph});
	return $self;
}

sub name {
	my $self = shift;
	return $self->{name};
}

sub run_command {
	my ($self, $command, @arguments) = @_;
	my ($plugin, $subcommand) = $command =~ m{ ^ ([^/]+) / (.*) }x ? ($self->{graph}->lookup_plugin($1), $2) : ($self, $command);
	my $callback = $plugin->get_commands->{$subcommand} or Carp::croak("No such command $subcommand in $self->{name}");
	return $callback->(@arguments);
}

sub run_trans {
	my ($self, $trans, @arguments) = @_;
	my ($plugin, $subtrans) = $trans =~ m{ ^ ([^/]+) / (.*) }x ? ($self->{graph}->lookup_plugin($1), $2) : ($self, $trans);
	my $callback = $plugin->get_trans->{$subtrans} or Carp::croak("No such transformation $trans in $self->{name}");
	return $callback->(@arguments);
}

sub get_commands {
	return {};
}

sub get_trans {
	return {};
}

sub to_hashref {
	my $self = shift;
	return {
		module => ref($self),
		name   => $self->{name},
	};
}

1;

# ABSTRACT: A base role for various types of plugins
