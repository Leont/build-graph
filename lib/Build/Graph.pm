package Build::Graph;

use strict;
use warnings;

use Carp qw//;

use Build::Graph::Node;

use Build::Graph::Variable::Wildcard;
use Build::Graph::Variable::Subst;
use Build::Graph::Variable::Free;

use Build::Graph::Util;

use Scalar::Util ();

sub new {
	my $class = shift;
	return bless {
		nodes     => {},
		plugins   => {},
		variables => {},
	}, $class;
}

sub _get_value {
	my ($variables, $key) = @_;
	my $raw = exists $variables->{$key} ? $variables->{$key} : Carp::croak("No such variable $key");
	if (Scalar::Util::blessed($raw) && $raw->isa('Build::Graph::Role::Variable')) {
		my @values = $raw->entries;
		return @values == 1 ? $values[0] : join ' ', @values;
	}
	else {
		return $raw;
	}
}

sub _get_values {
	my ($variables, $key) = @_;
	my $raw = exists $variables->{$key} ? $variables->{$key} : Carp::croak("No such variable $key");
	if (Scalar::Util::blessed($raw) && $raw->isa('Build::Graph::Role::Variable')) {
		return $raw->entries;
	}
	else {
		return ref($raw) eq 'ARRAY' ? @{ $raw } : $raw;
	}
}

sub _expand {
	my ($variables, $key, $count) = @_;
	Carp::croak("Deep variable recursion detected involving $key") if $count > 20;
	if ($key =~ / \A \@\( ([\w.-]+) \) \z /xm) {
		return map { _expand($variables, $_, $count + 1) } _get_values($variables, $1)
	}
	elsif ($key =~ / \A %\( ([\w.,-]+) \) \z /xm) {
		my @keys = grep { exists $variables->{$_} } split /,/, $1;
		return { map { $_ => _expand($variables, _get_value($variables, $_), $count + 1) } @keys };
	}
	$key =~ s/ ( (?<!\\)(?>\\\\)* ) \$\( ([\w.-]+) \) / $1 . _expand($variables, _get_value($variables, $2), $count + 1) /gex;

	return $key;
}

sub expand {
	my ($self, $options, @values) = @_;
	my %all = ( %{ $self->{variables} }, %{$options} );
	return map { _expand(\%all, $_, 1) } @values;
}

sub lookup_plugin {
	my ($self, $name) = @_;
	return $self->{plugins}{$name};
}

sub _get_node {
	my ($self, $key) = @_;
	return $self->{nodes}{$key};
}

sub add_file {
	my ($self, $name, %args) = @_;
	my $ret = $self->_add_node($name, %args);

	$_->match($name) for grep { $_->isa('Build::Graph::Variable::Wildcard') } values %{ $self->{variables} };
	return $ret;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	return $self->_add_node($name, %args, phony => 1);
}

sub _add_node {
	my ($self, $name, %args) = @_;
	Carp::croak("Node '$name' already exists in database") if !$args{override} && exists $self->{nodes}{$name};
	$self->{nodes}{$name} = "Build::Graph::Node"->new(%args, name => $name, graph => $self);;
	$self->add_variable($args{add_to}, $name) if $args{add_to};
	return $name;
}

sub add_wildcard {
	my ($self, $name, %args) = @_;
	$args{pattern} = Build::Graph::Util::glob_to_regex($args{pattern}) if ref($args{pattern}) ne 'Regexp';
	my $wildcard = Build::Graph::Variable::Wildcard->new(%args);
	$self->{variables}{$name} = $wildcard;
	$wildcard->match($_) for grep { $self->{nodes}{$_}->isa('Build::Graph::Node::File') } keys %{ $self->{nodes} };
	return;
}

sub add_variable {
	my ($self, $name, @values) = @_;
	$self->{variables}{$name} ||= Build::Graph::Variable::Free->new();
	$self->{variables}{$name}->add_entries(@values);
	return;
}

sub add_subst {
	my ($self, $name, $sourcename, %args) = @_;
	my $source = $self->{variables}{$sourcename};
	my $sub = Build::Graph::Variable::Subst->new(%args, graph => $self, name => $name);
	$source->add_subst($sub);
	$self->{variables}{$name} = $sub;
	return;
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
	my $self      = shift;
	my %nodes     = map { $_ => $self->_get_node($_)->to_hashref } keys %{ $self->{nodes} };
	my %variables = map { $_ => $self->{variables}{$_}->to_hashref } keys %{ $self->{variables} };
	my %plugins   = map { $_ => $self->{plugins}{$_}->to_hashref } keys %{ $self->{plugins} };
	return {
		plugins   => \%plugins,
		nodes     => \%nodes,
		variables => \%variables,
	};
}

sub _load_variables {
	my ($self, $source, $name) = @_;
	my $entry = $source->{$name};
	my @subst_names = @{ $entry->{substs} || [] };
	_load_variables($self, $source, $_) for grep { not $self->{variables}{$_} } @subst_names;
	my @substs  = map { $self->{variables}{$_} } @subst_names;
	my $class   = "Build::Graph::Variable::\u$entry->{type}";
	my $entries = $class->new(%{$entry}, substs => \@substs, graph => $self, name => $name);
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
		$self->{nodes}{$key} = Build::Graph::Node->new(%{$value}, name => $key, graph => $self);
	}
	for my $name (keys %{ $hashref->{plugins} }) {
		my $args = $hashref->{plugins}{$name};
		$self->load_plugin($args->{module}, %{$args}, name => $name);
	}
	return $self;
}

sub load_plugin {
	my ($self, $module, %args) = @_;
	(my $filename = "$module.pm") =~ s{::}{/}g;
	require $filename;
	my $plugin = $module->new(%args, graph => $self);
	my $name = $plugin->name;
	Carp::croak("Plugin collision: $name already exists") if exists $self->{plugins}{$name};
	$self->{plugins}{$name} = $plugin;
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
