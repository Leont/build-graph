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

sub _rel_to_abs {
	my ($value, $pwd) = @_;
	return $value if not defined $value or not @{$value} or $value->[0] =~ m{/};
	return [ "$pwd/" . $value->[0], @{$value}[ 1..$#{ $value } ] ];
}

for my $method (qw/add_file add_phony/) {
	no strict 'refs';
	*{$method} = sub {
		my ($self, $name, %options) = @_;
		$options{action} = _rel_to_abs($options{action}, $self->{name});
		return $self->{graph}->$method($name, %options);
	};
}

for my $method (qw/add_variable add_wildcard/) {
	no strict 'refs';
	*{$method} = sub {
		my ($self, $name, @arguments) = @_;
		return $self->{graph}->$method($name, @arguments);
	};
}

sub add_subst {
	my ($self, $sink, $source, %options) = @_;
	$options{trans}  = _rel_to_abs($options{trans}, $self->{name});
	$options{action} = _rel_to_abs($options{action}, $self->{name});
	return $self->{graph}->add_subst($sink, $source, %options);
}

1;

# ABSTRACT: A base role for various types of plugins
