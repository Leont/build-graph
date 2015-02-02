package Build::Graph::Role::Node;

use Moo::Role;

use Build::Graph::Action;

requires qw/phony weak/;

has name => (
	is       => 'ro',
	required => 1,
);

has _dependencies => (
	is       => 'ro',
	default  => sub { [] },
	init_arg => 'dependencies',
);

sub dependencies {
	my $self = shift;
	return @{ $self->_dependencies };
}

sub add_dependencies {
	my ($self, @dependencies) = @_;
	push @{ $self->_dependencies }, @dependencies;
	return;
}

my $from_string = sub {
	my $value = shift;
	return Build::Graph::Action->new(command => $value);
};
my $from_hashref = sub {
	my $value = shift;
	return Build::Graph::Action->new(%{$value});
};

has _actions => (
	is       => 'ro',
	default  => sub { [] },
	init_arg => 'actions',
	coerce   => sub {
		my $value = shift;
		my $type  = ref $value;
		if ($type eq 'Build::Graph::Action') {
			return [$value];
		}
		elsif ($type eq 'ARRAY') {
			return [ map { ref() ? $from_hashref->($_) : $from_string->($_) } @{$value} ];
		}
		elsif ($type eq 'HASH') {
			return [ $from_hashref->($value) ];
		}
		elsif ($type eq '') {
			return [ $from_string->($value) ];
		}
	},
);

sub actions {
	my $self = shift;
	return @{ $self->_actions };
}

sub run {
	my ($self, $graph, $options) = @_;
	for my $action ($self->actions) {
		my $command = $action->command;
		my $callback = $graph->commandset->get($command) or Carp::croak("Command $command doesn't exist");
		$callback->($graph->info_class->new(%{$options}, name => $self->name, arguments => $action->arguments));
	}
	return;
}

sub to_hashref {
	my $self = shift;
	my @dependencies = $self->dependencies;
	my @actions = map { $_->to_hashref } $self->actions;
	return {
		(dependencies => \@dependencies) x !!@dependencies,
		(actions      => \@actions) x !!@actions,
		class        => ref($self),
	};
}

1;

=attr dependencies

=attr action

=method to_hashref

