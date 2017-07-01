package Build::Graph;

use strict;
use warnings;

use Carp qw//;

use Build::Graph::Node::File;
use Build::Graph::Node::Phony;

use Build::Graph::Variable::Pattern;
use Build::Graph::Variable::Subst;
use Build::Graph::Variable::Free;

use Build::Graph::Namespace;

use Build::Graph::Util;

use Scalar::Util ();

sub new {
	my $class = shift;
	my $self = bless {
		nodes       => {},
		commandsets => {},
		variables   => {},
	}, $class;
	$self->{actions}         = Build::Graph::Namespace->new(graph => $self, type => 'action');
	$self->{transformations} = Build::Graph::Namespace->new(graph => $self, type => 'transformation');
	return $self;
}

sub _get_value {
	my ($variables, $key, $optional) = @_;
	return $key if $key =~ /^[\$@%]$/;
	my $raw = $optional || exists $variables->{$key} ? $variables->{$key} : Carp::croak("No such variable $key");
	if (Scalar::Util::blessed($raw) && $raw->isa('Build::Graph::Role::Variable')) {
		my @values = $raw->entries;
		return @values == 1 ? $values[0] : join ' ', @values;
	}
	else {
		return $raw;
	}
}

sub _get_values {
	my ($variables, $key, $optional) = @_;
	my $raw = $optional || exists $variables->{$key} ? $variables->{$key} : Carp::croak("No such variable $key");
	if (Scalar::Util::blessed($raw) && $raw->isa('Build::Graph::Role::Variable')) {
		return $raw->entries;
	}
	else {
		return ref($raw) eq 'ARRAY' ? @{ $raw } : defined $raw ? $raw : ();
	}
}

sub _expand_list {
	my ($variables, $value, $count) = @_;
	Carp::croak("Deep variable recursion detected involving $value") if $count > 20;
	if (not defined $value) {
		return $value;
	}
	elsif (ref($value) eq 'ARRAY') {
		return [ map { _expand_list($variables, $_, $count + 1)  } @{ $value } ];
	}
	elsif (ref($value) eq 'HASH') {
		return { map { $_ => _expand_scalar($variables, $value->{$_}, $count + 1) } keys %{ $value } };
	}
	elsif (ref $value) {
		return $value;
	}
	elsif ($value =~ / \A @ ([\w.-]+) (\??) \z /xm) {
		return map { _expand_list($variables, $_, $count + 1) } _get_values($variables, $1, $2);
	}
	elsif ($value =~ / \A % \{ ([\w.,-]+) \} \z /xm) {
		return { map { $_ => _expand_scalar($variables, _get_value($variables, $_, 1), $count + 1) } split /,/, $1 };
	}
	elsif ($value =~ / \A % ([\w.-]+) \z /xm) {
		return { $1 => _expand_scalar($variables, _get_value($variables, $1, 1), $count + 1) };
	}
	elsif ($value =~ / \A \$ ([\w.-]+) (\??) \z /xms) {
		return _expand_scalar($variables, _get_value($variables, $1, $2), $count + 1);
	}
	else {
		$value =~ s/ \$ ( [\w.-]+ | [\$@%] ) (\??) / _expand_scalar($variables, _get_value($variables, $1, $2), $count + 1) /gex;
		return $value;
	}
}

sub _expand_scalar {
	my ($variables, $value, $count) = @_;
	my @ret = _expand_list($variables, $value, $count);
	return undef if not @ret;
	return $ret[0] if @ret == 1;
	return join ' ', @ret;
}

sub expand {
	my ($self, $options, @values) = @_;
	my %all = ( %{ $self->{variables} }, %{$options} );
	if (wantarray) {
		return map { _expand_list(\%all, $_, 1) } @values;
	}
	else {
		die "Can't expand multiple value in scalar context" if @values != 1;
		return _expand_scalar(\%all, $values[0], 1);
	}
}

sub escape {
	my ($self, $string) = @_;
	$string =~ s/ ( ^ \$ (?= [\w.\$@%-] ) | ^ @ (?= [\w.-] ) | ^ % (?= [\w.{-] ) |  \$ (?= [\w.\$-] ) ) /\$$1/gsx;
	return $string;
}

sub _get_node {
	my ($self, $key) = @_;
	return $self->{nodes}{$key};
}

sub add_file {
	my ($self, $name, %args) = @_;
	my $ret = $self->_add_node($name, 'Build::Graph::Node::File', %args);

	$self->add_variable('all-files', $name);
	return $ret;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	return $self->_add_node($name, 'Build::Graph::Node::Phony', %args);
}

sub _add_node {
	my ($self, $name, $class, %args) = @_;
	Carp::croak("Node '$name' already exists in database") if !$args{override} && exists $self->{nodes}{$name};
	$self->{nodes}{$name} = $class->new(%args, name => $name, graph => $self);
	$self->add_variable($args{add_to}, $name) if $args{add_to};
	return $name;
}

sub add_pattern {
	my ($self, $name, %args) = @_;
	$args{pattern} = Build::Graph::Util::glob_to_regex($args{pattern}) if ref($args{pattern}) ne 'Regexp';
	my $pattern = Build::Graph::Variable::Pattern->new(%args, name => $name);
	$self->{variables}{$name} = $pattern;
	my $source_name = 'all-files' if not defined $args{source};
	$self->{variables}{$source_name}->add_dependent($pattern);
	return;
}

sub add_variable {
	my ($self, $name, @values) = @_;
	$self->{variables}{$name} ||= Build::Graph::Variable::Free->new(name => $name);
	$self->{variables}{$name}->add_entries(@values);
	return;
}

sub add_subst {
	my ($self, $name, $source_name, %args) = @_;
	my $sub = Build::Graph::Variable::Subst->new(%args, graph => $self, name => $name);
	$self->{variables}{$source_name}->add_dependent($sub);
	$self->{variables}{$name} = $sub;
	return;
}

sub actions {
	my $self = shift;
	return $self->{actions};
}

sub transformations {
	my $self = shift;
	return $self->{transformations};
}

my $node_sorter;
$node_sorter = sub {
	my ($self, $current, $callback, $seen, $loop) = @_;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
	return if $seen->{$current}++;
	local $loop->{$current} = 1;
	if (my $node = $self->_get_node($current)) {
		$self->$node_sorter($_, $callback, $seen, $loop) for $node->dependencies;
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
	my ($self) = @_;
	my %nodes       = map { $_ => $self->_get_node($_)->to_hashref } keys %{ $self->{nodes} };
	my %variables   = map { $_ => $self->{variables}{$_}->to_hashref } keys %{ $self->{variables} };
	my %commandsets = map { $_ => $self->{commandsets}{$_}->to_hashref } keys %{ $self->{commandsets} };
	return {
		commandsets => \%commandsets,
		nodes       => \%nodes,
		variables   => \%variables,
	};
}

sub _load_variables {
	my ($self, $source, $name) = @_;
	my $entry = $source->{$name};
	my @dependent_names = @{ $entry->{dependents} || [] };
	_load_variables($self, $source, $_) for grep { not $self->{variables}{$_} } @dependent_names;
	my @dependents  = map { $self->{variables}{$_} } @dependent_names;
	my $class   = "Build::Graph::Variable::\u$entry->{type}";
	my $entries = $class->new(%{$entry}, dependents => \@dependents, graph => $self, name => $name);
	$self->{variables}{$name} = $entries;
	return;
}

sub load {
	my ($class, $hashref) = @_;
	my $self = Build::Graph->new;
	for my $name (keys %{ $hashref->{variables} }) {
		next if $self->{variables}{$name};
		_load_variables($self, $hashref->{variables}, $name);
	}
	for my $key (keys %{ $hashref->{nodes} }) {
		my $value = $hashref->{nodes}{$key};
		my $class = 'Build::Graph::Node::' . ( $value->{phony} ? 'Phony' : 'File' );
		$self->{nodes}{$key} = $class->new(%{$value}, name => $key, graph => $self);
	}
	for my $name (keys %{ $hashref->{commandsets} }) {
		my $args = $hashref->{commandsets}{$name};
		$self->load_commands($args->{module}, %{$args}, name => $name);
	}
	return $self;
}

sub load_commands {
	my ($self, $module, %args) = @_;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
	my $plugin = $module->new(%args, graph => $self);
	my $name = $plugin->name;
	Carp::croak("Plugin collision: $name already exists") if exists $self->{commandsets}{$name};
	$self->{commandsets}{$name} = $plugin;
	return $plugin;
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
