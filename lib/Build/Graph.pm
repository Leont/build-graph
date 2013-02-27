package Build::Graph;
use Moo;
use Carp ();
use Build::Graph::Node;
use Build::Graph::CommandSet;
use List::MoreUtils qw//;
use Module::Runtime qw//;

has _nodes => (
	is       => 'ro',
	init_arg => undef,
	default  => sub { {} },
);

sub get_node {
	my ($self, $key) = @_;
	return $self->_nodes->{$key};
}

sub add_file {
	my ($self, $name, %args) = @_;
	Carp::croak("File '$name' already exists in database") if !$args{override} && exists $self->_nodes->{$name};
	my $node = Build::Graph::Node->new(%args, phony => 0);
	$self->_nodes->{$name} = $node;
	return;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	Carp::croak("Phony '$name' already exists in database") if !$args{override} && exists $self->_nodes->{$name};
	my $node = Build::Graph::Node->new(%args, phony => 1);
	$self->_nodes->{$name} = $node;
	return;
}

has commands => (
	is      => 'ro',
	default => sub { Build::Graph::CommandSet->new },
);

has info_class => (
	is      => 'ro',
	default => sub { 'Build::Graph::Info' },
);

my $node_sorter;
$node_sorter = sub {
	my ($self, $current, $callback, $seen, $loop) = @_;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
	return if $seen->{$current}++;
	my $node = $self->get_node($current) or Carp::croak("Node $current doesn't exist");
	local $loop->{$current} = 1;
	$self->$node_sorter($_, $callback, $seen, $loop) for $node->dependencies;
	$callback->($current);
	return;
};

sub _sort_nodes {
	my ($self, $startpoint) = @_;
	my @ret;
	$self->$node_sorter($startpoint, sub { push @ret, $_[0] }, {}, {});
	return @ret;
}

my $newer = sub {
	my ($destination, $source) = @_;
	return 1 if not -e $source;
	return 0 if -d $source;
	return -M $destination > -M $source;
};

my $run_node = sub {
	my ($self, $node_name, $seen_phony, $options) = @_;
	my $node = $self->get_node($node_name);
	if ($node->phony) {
		return if $seen_phony->{$node_name}++;
	}
	else {
		my @files = grep { !$self->get_node($_)->phony } sort $node->dependencies;
		return if -e $node_name and not List::MoreUtils::any { $newer->($node_name, $_) } @files;
	}
	$node->make_dir($node_name) if $node->need_dir;
	for my $action ($node->actions) {
		my $callback = $self->commands->get($action->command) or Carp::croak("Command ${ \$action->command } doesn't exist");
		$callback->($self->info_class->new(name => $node_name, arguments => $action->arguments, %{$options}));
	}
};

sub run {
	my ($self, $startpoint, %options) = @_;
	my %seen_phony;
	Module::Runtime::require_module($self->info_class);
	$self->$node_sorter($startpoint, sub { $self->$run_node($_[0], \%seen_phony, \%options) }, {}, {});
	return;
}

sub nodes_to_hashref {
	my $self = shift;
	my %ret;
	for my $name (keys %{ $self->_nodes }) {
		$ret{$name} = $self->get_node($name)->to_hashref;
	}
	return \%ret;
}

sub load_from_hashref {
	my ($self, $serialized) = @_;
	for my $key (keys %{$serialized}) {
		$self->_nodes->{$key} = Build::Graph::Node->new($serialized->{$key});
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
