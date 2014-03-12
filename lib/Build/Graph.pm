package Build::Graph;

use Moo;

use Build::Graph::CommandSet;
use Carp qw//;
use Module::Runtime qw//;

use Build::Graph::Node::File;
use Build::Graph::Node::Phony;

has _nodes => (
	is       => 'ro',
	init_arg => 'nodes',
	default  => sub { {} },
	coerce   => sub {
		my $nodes = shift;
		for my $key (keys %{$nodes}) {
			if (ref($nodes->{$key}) eq 'HASH') {
				my $class = delete $nodes->{$key}{class};
				$nodes->{$key} = $class->new(%{ $nodes->{$key} }, name => $key);
			}
		}
		return $nodes;
	},
);

sub get_node {
	my ($self, $key) = @_;
	return $self->_nodes->{$key};
}

sub add_file {
	my ($self, $name, %args) = @_;
	Carp::croak("File '$name' already exists in database") if !$args{override} && exists $self->_nodes->{$name};
	my $node = Build::Graph::Node::File->new(%args, name => $name);
	$self->_nodes->{$name} = $node;
	return;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	Carp::croak("Phony '$name' already exists in database") if !$args{override} && exists $self->_nodes->{$name};
	my $node = Build::Graph::Node::Phony->new(%args, name => $name);
	$self->_nodes->{$name} = $node;
	return;
}

has loader_class => (
	is => 'ro',
	default => 'Build::Graph::ClassLoader',
);

has loader_args => (
	is => 'ro',
	default => sub { {} },
);

has loader => (
	is => 'lazy',
	default => sub {
		my $self = shift;
		my $class = $self->loader_class;
		Module::Runtime::require_module($class);
		return $class->new(%{ $self->loader_args }, graph => $self);
	},
);

has commandset => (
	is      => 'lazy',
	default => sub {
		my $self = shift;
		return Build::Graph::CommandSet->new(loader => $self->loader);
	},
);

has info_class => (
	is      => 'ro',
	default => 'Build::Graph::Info',
);

my $node_sorter;
$node_sorter = sub {
	my ($self, $current, $callback, $seen, $loop) = @_;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
	return if $seen->{$current}++;
	my $node = $self->get_node($current) or Carp::croak("Node $current doesn't exist");
	local $loop->{$current} = 1;
	$self->$node_sorter($_, $callback, $seen, $loop) for $node->dependencies;
	$callback->($current, $node);
	return;
};

sub run {
	my ($self, $startpoint, %options) = @_;
	Module::Runtime::require_module($self->info_class);
	$self->$node_sorter($startpoint, sub { $_[1]->run($self, \%options) }, {}, {});
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
		commandset => $self->commandset->to_hashref,
		loader     => $self->loader->to_hashref,
		nodes      => $self->_nodes_to_hashref,
		info_class => $self->info_class,
	};
}

sub _nodes_to_hashref {
	my $self = shift;
	my %ret = map { $_ => $self->get_node($_)->to_hashref } keys %{ $self->_nodes };
	return \%ret;
}

sub load {
	my ($self, $hashref) = @_;
	my $loader_class = delete $hashref->{loader}{module};
	my $ret = Build::Graph->new(
		loader_class => $loader_class,
		loader_args  => $hashref->{loader},
		nodes        => $hashref->{nodes},
		info_class   => $hashref->{info_class},
	);
	for my $module (values %{ $hashref->{commandset} }) {
		$ret->commandset->load($module->{module});
	}
	return $ret;
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
