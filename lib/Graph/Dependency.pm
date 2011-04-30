package Graph::Dependency;
use Any::Moose;
use Carp ();
use Graph::Dependency::Node;
use List::MoreUtils qw//;

has nodes => (
	isa      => 'HashRef[Graph::Dependency::Node]',
	traits   => ['Hash'],
	init_arg => undef,
	default  => sub { {} },
	handles  => {
		get_node    => 'get',
		_set_node   => 'set',
	},
);

sub add_file {
	my ($self, $name, %args) = @_;
	Carp::croak('File already exists in database') if !$args{override} && $self->get_node($name);
	my $node = Graph::Dependency::Node->new(%args, phony => 0);
	$self->_set_node($name, $node);
	return;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	Carp::croak('Phony already exists in database') if !$args{override} && $self->get_node($name);
	my $node = Graph::Dependency::Node->new(%args, phony => 1);
	$self->_set_node($name, $node);
	return;
}

has actions => (
	isa      => 'HashRef[CodeRef]',
	traits   => ['Hash'],
	init_arg => undef,
	default  => sub { {} },
	handles  => {
		all_actions => 'keys',
		get_action  => 'get',
		add_action  => 'set',
	},
);

my $node_sorter;
$node_sorter = sub {
	my ($self, $current, $list, $seen, $loop) = @_;
	return if $seen->{$current}++;
	Carp::croak("$current has a circular dependency, aborting!\n") if exists $loop->{$current};
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
			my @files = grep { !$self->get_node($_)->phony } sort +$node->dependencies->all;
			next if -e $node_name and not List::MoreUtils::any { $newer->($node_name, $_) } @files;
		}
		my $action = $self->get_action($node->action) or Carp::croak("Action ${ \$node->action } doesn't exist");
		$action->($node_name, $node);
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
