package Build::Graph;

use strict;
use warnings;

use Carp qw//;

use Build::Graph::Node::File;
use Build::Graph::Node::Phony;

use Build::Graph::Wildcard;
use Build::Graph::Subst;
use Build::Graph::Variable;

sub new {
	my ($class, %args) = @_;

	return bless {
		nodes        => $args{nodes}     || {},
		plugins      => $args{plugins},
		wildcards    => $args{wildcards} || [],
		named        => $args{named}     || {},
		names        => $args{names}     || [],
		seen         => $args{seen}      || {},
	}, $class;
}

sub get_node {
	my ($self, $key) = @_;
	return $self->{nodes}{$key};
}

sub expand {
	my ($self, $key, $options) = @_;
	if ($key =~ /\A \@\( ([\w.-]+)  \) \z /xms) {
		my $variable = $self->{named}{$1} or die "No such variable $1\n";
		return $variable->entries;
	}
	elsif ($key =~ /\A \$\( ([\w.-]+)  \) \z /xms) {
		my $argument = $options->{$1} or die "No such argument $1\n";
		return $argument;
	}
	elsif ($key =~ /\A \%\( ([\w.,-]+)  \) \z /xms) {
		my @keys = grep { exists $options->{$_} } split /, ?/, $1;
		return { map { $_ => $options->{$_} } @keys };
	}
	elsif ($key eq '{}') {
		return {};
	}
	return $key;
}

sub run_command {
	my ($self, $options, $command, @raw_args) = @_;
	my $callback = $self->plugins->get_command($command) or Carp::croak("Command $command doesn't exist");
	return $callback->(map { $self->expand($_, $options) } @raw_args);
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
	my ($self, $name, %args) = @_;
	if (ref($args{pattern}) ne 'Regexp') {
		require Text::Glob;
		$args{pattern} = Text::Glob::glob_to_regex($args{pattern});
	}
	my $wildcard = Build::Graph::Wildcard->new(%args, graph => $self, name => $name);
	push @{ $self->{wildcards} }, $wildcard;
	$self->{named}{$name} = $wildcard;
	push @{ $self->{names} }, $name;
	$wildcard->match($_) for grep { !$self->{nodes}{$_}->phony } keys %{ $self->{nodes} };
	return $wildcard;
}

sub add_variable {
	my ($self, $name, @values) = @_;
	$self->{named}{$name} ||= Build::Graph::Variable->new(name => $name);
	$self->{named}{$name}->add_entries(@values);
	push @{ $self->{names} }, $name;
	return;
}

sub match {
	my ($self, @names) = @_;
	for my $name (@names) {
		next if $self->{seen}{$name}++;
		for my $wildcard (@{ $self->{wildcards} }) {
			$wildcard->match($name);
		}
	}
	return;
}

sub add_subst {
	my ($self, $name, $wildcard, %args) = @_;
	my $sub = Build::Graph::Subst->new(%args, graph => $self, name => $name);
	$wildcard->on_file($sub);
	$self->{named}{$name} = $sub;
	push @{ $self->{names} }, $name;
	return $sub;
}

sub plugins {
	my $self = shift;
	return $self->{plugins} ||= do {
		require Build::Graph::PluginSet;
		Build::Graph::PluginSet->new;
	};
}

my $node_sorter;
$node_sorter = sub {
	my ($self, $current, $callback, $seen, $loop) = @_;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
	return if $seen->{$current}++;
	local $loop->{$current} = 1;
	if (my $node = $self->get_node($current)) {
		$self->$node_sorter($_, $callback, $seen, $loop) for map { $self->expand($_, {}) } $node->dependencies;
		$callback->($current, $node);
	}
	elsif (not -e $current) {
		Carp::croak("Node $current doesn't exist");
	}
	return;
};

sub run {
	my ($self, $startpoint, %options) = @_;
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
	my %nodes = map { $_ => $self->get_node($_)->to_hashref } keys %{ $self->{nodes} };
	my @named = map { $self->{named}{$_}->to_hashref } @{ $self->{names} };
	return {
		plugins    => $self->{plugins} ? $self->plugins->to_hashref : [],
		nodes      => \%nodes,
		named      => \@named,
		seen       => [ sort keys %{ $self->{seen} } ],
	};
}

sub load {
	my ($class, $hashref) = @_;
	my $self = Build::Graph->new(seen => { map { $_ => 1 } @{ $hashref->{seen} } });
	for my $named (reverse @{ $hashref->{named} }) {
		my $entries = $named->{class}->new(%{ $named }, graph => $self);
		$self->{named}{ $named->{name} } = $entries;
		unshift @{ $self->{names} }, $named->{name};
		unshift @{ $self->{wildcards} }, $entries if $entries->isa('Build::Graph::Wildcard')
	}
	for my $key (keys %{ $hashref->{nodes} }) {
		my $value = $hashref->{nodes}{$key};
		$self->{nodes}{$key} = $value->{class}->new(%{$value}, name => $key, graph => $self);
	}
	for my $plugin (@{ $hashref->{plugins} }) {
		$self->load_plugin($plugin->{name}, $plugin->{module});
	}
	return $self;
}

sub load_plugin {
	my ($self, $name, $module, %args) = @_;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
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
