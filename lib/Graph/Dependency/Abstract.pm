package Graph::Dependency::Abstract;
use Any::Moose;
use Carp ();

has nodes => (
	isa => 'HashRef[Graph::Dependency::Abstract::Node]',
	traits => ['Hash'],
	init_arg => undef,
	default => sub { {} },
	handles => {
		get_node => 'get',
		'_set_node' => 'set',
	},
);

sub add_file {
	my ($self, $name, %args) = @_;
	Carp::croak('File already exists in database') if !$args{override} && $self->get_node($name);
	my $node = Graph::Dependency::Abstract::Node->new(%args, phony => 0, name => $name);
	$self->_set_node($name, $node);
	return;
}

sub add_phony {
	my ($self, $name, %args) = @_;
	Carp::croak('Phony already exists in database') if !$args{override} && $self->get_node($name);
	my $node = Graph::Dependency::Abstract::Node->new(%args, phony => 1, name => $name);
	$self->_set_node($name, $node);
	return;
}

has actions => (
	isa => 'HashRef[Graph::Dependency::Abstract::Action]',
	init_arg => undef,
	default => sub { {} },
	handles => {
		all_actions => 'keys',
		get_action => 'get',
		add_action => 'set',
	},
);

sub compile {
	my ($self, $startpoint) = @_;
	my $compiler = Graph::Dependency::Compiling->new;
	$self->get_node($startpoint)->compile($startpoint, $compiler);
	return Graph::Dependency::OP->new(nodes => { $compiler->all_compiled });
}

1;

__END__

=method get_node

=method add_file

=method add_phony

=method all_actions

=method get_action

=method add_action

=method compile

