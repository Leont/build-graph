package Build::Graph;

use strict;
use warnings;

use Carp qw//;
use Module::Runtime qw//;

use Build::Graph::Node::File;
use Build::Graph::Node::Phony;

sub new {
	my ($class, %args) = @_;

	return bless {
		nodes        => $args{nodes}        || {},
		plugins      => $args{plugins},
		info_class   => $args{info_class}   || 'Build::Graph::Info',
		wildcards    => $args{wildcards}    || [],
		named        => $args{named}        || {},
	}, $class;
}

sub get_node {
	my ($self, $key) = @_;
	return $self->{nodes}{$key};
}

sub expand {
	my ($self, @keys) = @_;
	return map { /\A \$\( ([\w.-]+)  \) \z /xms ? @{ $self->{named}{$1} } : $_ } @keys;
}

sub add_file {
	my ($self, $name, %args) = @_;
	Carp::croak("File '$name' already exists in database") if !$args{override} && exists $self->{nodes}{$name};
	my $node = Build::Graph::Node::File->new(%args, name => $name, graph => $self);
	$self->{nodes}{$name} = $node;
	$self->match($name);
	return $name;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	Carp::croak("Phony '$name' already exists in database") if !$args{override} && exists $self->{nodes}{$name};
	my $node = Build::Graph::Node::Phony->new(%args, name => $name, graph => $self);
	$self->{nodes}{$name} = $node;
	$self->match($name);
	return $name;
}

sub add_wildcard {
	my ($self, %args) = @_;
	if (!$args{matcher} && $args{pattern}) {
		my $pattern = delete $args{pattern};
		if (ref($pattern) ne 'Regexp') {
			require Text::Glob;
			$pattern = Text::Glob::glob_to_regex($pattern);
		}
		$args{matcher} = sub {
			my $filename = shift;
			require File::Basename;
			return File::Basename::basename($filename) =~ $pattern;
		};
	}
	require Build::Graph::Wildcard;
	my $wildcard = Build::Graph::Wildcard->new(%args);
	push @{ $self->{wildcards} }, $wildcard;
	$wildcard->match($_) for grep { !$self->{nodes}{$_}->phony } keys %{ $self->{nodes} };
	$wildcard->on_file(sub { my $filename = shift; push @{ $self->{named}{ $args{name} } }, $filename }) if $args{name};
	return $wildcard;
}

sub add_named {
	my ($self, $name, @values) = @_;
	push @{ $self->{named}{$name} }, @values;
	return;
}

sub match {
	my ($self, @names) = @_;
	for my $name (@names) {
		for my $wildcard (@{ $self->{wildcards} }) {
			$wildcard->match($name);
		}
	}
	return;
}

sub add_subst {
	my ($self, $wildcard, %args) = @_;
	require Build::Graph::Subst;
	my $sub = Build::Graph::Subst->new(%args, graph => $self);
	$wildcard->on_file(sub {
		my $source = shift;
		my $target = $sub->process($source);
		push @{ $self->{named}{ $args{name} } }, $target if $args{name};
	});
	return $sub;
}

sub plugins {
	my $self = shift;
	return $self->{plugins} ||= do {
		require Build::Graph::PluginSet;
		Build::Graph::PluginSet->new;
	};
}

sub info_class {
	my $self = shift;
	return $self->{info_class};
}

my $node_sorter;
$node_sorter = sub {
	my ($self, $current, $callback, $seen, $loop) = @_;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
	return if $seen->{$current}++;
	local $loop->{$current} = 1;
	if (my $node = $self->get_node($current)) {
		$self->$node_sorter($_, $callback, $seen, $loop) for $self->expand($node->dependencies);
		$callback->($current, $node);
	}
	elsif (not -e $current) {
		Carp::croak("Node $current doesn't exist");
	}
	return;
};

sub run {
	my ($self, $startpoint, %options) = @_;
	Module::Runtime::require_module($self->info_class);
	$self->$node_sorter($startpoint, sub { $_[1]->run(\%options) }, {}, {});
	return;
}

sub _sort_nodes {
	my ($self, $startpoint) = @_;
	my @ret;
	$self->$node_sorter($startpoint, sub { push @ret, $_[0] }, {}, {});
	return @ret;
}

sub to_hashref {
	my $self = shift;
	return {
		plugins    => $self->plugins->to_hashref,
		nodes      => $self->_nodes_to_hashref,
		info_class => $self->info_class,
		named      => $self->{named},
	};
}

sub _nodes_to_hashref {
	my $self = shift;
	my %ret = map { $_ => $self->get_node($_)->to_hashref } keys %{ $self->{nodes} };
	return \%ret;
}

sub load {
	my ($class, $hashref) = @_;
	my $ret          = Build::Graph->new(
		info_class   => $hashref->{info_class},
		named        => $hashref->{named},
	);
	for my $key (keys %{ $hashref->{nodes} }) {
		my $value = $hashref->{nodes}{$key};
		my $class = delete $value->{class};
		$ret->{nodes}{$key} = $class->new(%{$value}, name => $key, graph => $ret);
	}
	for my $plugin (@{ $hashref->{plugins} }) {
		$ret->load_plugin($plugin->{name}, $plugin->{module});
	}
	return $ret;
}

sub load_plugin {
	my ($self, $name, $module, %args) = @_;
	Module::Runtime::require_module($module);
	my $ret = $module->new(%args, name => $name);
	$self->plugins->add_plugin($name, $ret);
	return;
}

1;

# ABSTRACT: A simple dependency graph

=method get_node

=method add_file

=method add_phony

=method all_actions

=method get_action

=method add_action

=method run

=method nodes_to_hashref

=method load_from_hashref
