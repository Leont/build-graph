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
		plugins      => $args{plugins}   || {},
		matchers     => $args{matchers}  || [],
		wildcards    => $args{wildcards} || [],
		named        => $args{named}     || {},
		seen         => $args{seen}      || {},
	}, $class;
}

sub get_node {
	my ($self, $key) = @_;
	return $self->{nodes}{$key};
}

sub _expand {
	my ($self, $options, $key) = @_;
	$options ||= {};
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

sub expand {
	my ($self, $options, @values) = @_;
	return map { $self->_expand($options, $_) } @values;
}

sub run_command {
	my ($self, $command, @args) = @_;
	my ($groupname, $subcommand) = split m{/}, $command, 2;
	my $group = $self->{plugins}{$groupname};
	my $callback = $group ? $group->lookup_command($subcommand, $self) : Carp::croak("Command $command doesn't exist");
	return $callback->(@args);
}

sub run_subst {
	my ($self, $command, @args) = @_;
	my ($groupname, $subst) = split m{/}, $command, 2;
	my $group = $self->{plugins}{$groupname};
	my $subst_action = $group ? $group->lookup_subst($subst) : Carp::croak("No such subst $command");
	return $subst_action->(@args);
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
	$wildcard->match($_) for grep { $self->{nodes}{$_}->isa('Build::Graph::Node::File') } keys %{ $self->{nodes} };
	return $name;
}

sub add_variable {
	my ($self, $name, @values) = @_;
	$self->{named}{$name} ||= Build::Graph::Variable->new(name => $name);
	$self->{named}{$name}->add_entries(@values);
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
	my ($self, $name, $sourcename, %args) = @_;
	my $source = $self->{named}{$sourcename};
	my $sub = Build::Graph::Subst->new(%args, graph => $self, name => $name);
	$source->on_file($sub);
	$self->{named}{$name} = $sub;
	return $name;
}

sub add_plugin_handler {
	my ($self, $handler) = @_;
	push @{ $self->{matchers} }, $handler;
	for my $plugin (values %{ $self->{plugins} }) {
		$handler->($plugin);
	}
	return;
}

my $node_sorter;
$node_sorter = sub {
	my ($self, $current, $callback, $seen, $loop) = @_;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
	return if $seen->{$current}++;
	local $loop->{$current} = 1;
	if (my $node = $self->get_node($current)) {
		$self->$node_sorter($_, $callback, $seen, $loop) for $self->expand({}, $node->dependencies);
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
	my %named = map { $_ => $self->{named}{$_}->to_hashref } keys %{ $self->{named} };
	my @plugins = map { $_->serialize } values %{ $self->{plugins} };
	return {
		plugins    => \@plugins,
		nodes      => \%nodes,
		named      => \%named,
		seen       => [ sort keys %{ $self->{seen} } ],
	};
}

sub _load_named {
	my ($self, $source, $name) = @_;
	my $entry = $source->{$name};
	_load_named($self, $source, $_) for grep { not $self->{named}{$_} } @{ $entry->{substs} };
	my @substs = map { $self->{named}{$_} } @{ $entry->{substs} };
	my $entries = $entry->{class}->new(%{$entry}, substs => \@substs, graph => $self, name => $name);
	$self->{named}{$name} = $entries;
	unshift @{ $self->{wildcards} }, $entries if $entries->isa('Build::Graph::Wildcard')
}

sub load {
	my ($class, $hashref) = @_;
	my $self = Build::Graph->new(seen => { map { $_ => 1 } @{ $hashref->{seen} } });
	my @matchers;
	for my $name (keys %{ $hashref->{named} }) {
		next if $self->{named}{$name};
		_load_named($self, $hashref->{named}, $name);
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
	my $plugin = $module->new(%args, name => $name, graph => $self);
	$self->{plugins}{$name} = $plugin;
	for my $matcher (@{ $self->{matchers} }) {
		$matcher->($plugin);
	}
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
