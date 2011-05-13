package Build::Graph;
use Any::Moose;
use Carp ();
use Build::Graph::Node;
use Build::Graph::CommandSet;
use List::MoreUtils qw//;

has nodes => (
	isa      => 'HashRef[Build::Graph::Node]',
	traits   => ['Hash'],
	init_arg => undef,
	default  => sub { {} },
	handles  => {
		get_node    => 'get',
		_set_node   => 'set',
		_node_names => 'keys',
	},
);

sub add_file {
	my ($self, $name, %args) = @_;
	Carp::croak('File already exists in database') if !$args{override} && $self->get_node($name);
	my $node = Build::Graph::Node->new(%args, phony => 0);
	$self->_set_node($name, $node);
	return;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	Carp::croak('Phony already exists in database') if !$args{override} && $self->get_node($name);
	my $node = Build::Graph::Node->new(%args, phony => 1);
	$self->_set_node($name, $node);
	return;
}

has commands => (
	is => 'ro',
	isa => 'Build::Graph::CommandSet',
	default => sub { Build::Graph::CommandSet->new },
);

my $node_sorter;
$node_sorter = sub {
	my ($self, $current, $list, $seen, $loop) = @_;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
	return if $seen->{$current}++;
	my $node = $self->get_node($current) or Carp::croak("Node $current doesn't exist");
	my %new_loop = (%{$loop}, $current => 1);
	$self->$node_sorter($_, $list, $seen, \%new_loop) for $node->dependencies->all;
	push @{$list}, $current;
	return;
};

sub _sort_nodes {
	my ($self, $startpoint) = @_;
	my @ret;
	$self->$node_sorter($startpoint, \@ret, {}, {});
	return @ret;
}

my $newer = sub {
	my ($destination, $source) = @_;
	return 1 if not -e $source;
	return 0 if -d $source;
	return -M $destination > -M $source;
};

sub run {
	my ($self, $startpoint) = @_;
	my @nodes = $self->_sort_nodes($startpoint);
	my %seen_phony;
	for my $node_name (@nodes) {
		my $node = $self->get_node($node_name);
		if ($node->phony) {
			next if $seen_phony{$node_name}++;
		}
		else {
			my @files = grep { !$self->get_node($_)->phony } sort $node->dependencies->all;
			next if -e $node_name and not List::MoreUtils::any { $newer->($node_name, $_) } @files;
		}
		for my $action ($node->actions) {
			my $callback = $self->commands->get($action->command) or Carp::croak("Command ${ \$action->command } doesn't exist");
			$callback->($node_name, $action->arguments, $node->dependencies);
		}
	}
	return;
}

sub nodes_to_hashref {
	my $self = shift;
	my %ret;
	for my $name ($self->_node_names) {
		$ret{$name} = $self->get_node($name)->to_hashref;
	}
	return \%ret;
}

sub load_from_hashref {
	my ($self, $serialized) = @_;
	for my $key (keys %{$serialized}) {
		$self->_set_node($key, Build::Graph::Node->new($serialized->{$key}));
	}
	return;
}

1;

# ABSTRACT: A simple dependency graph

__END__

=method get_node

=method add_file

=method add_phony

=method all_actions

=method get_action

=method add_action

=method run

=method nodes_to_hashref

=method load_from_hashref
