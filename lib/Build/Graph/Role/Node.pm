package Build::Graph::Role::Node;

use strict;
use warnings;

use Carp ();

use Build::Graph::Action;

sub new {
	my ($class, %args) = @_;
	return bless {
		name         => $args{name} || Carp::croak('No name given'),
		dependencies => $args{dependencies} || [],
		actions      => $args{actions} ? _coerce_actions($args{actions}) : [],
	}, $class;
}

sub name {
	my $self = shift;
	return $self->{name};
}

sub dependencies {
	my $self = shift;
	return @{ $self->{dependencies} };
}

sub add_dependencies {
	my ($self, @dependencies) = @_;
	push @{ $self->{dependencies} }, @dependencies;
	return;
}

my $from_string = sub {
	my $value = shift;
	return Build::Graph::Action->new(command => $value);
};
my $from_array = sub {
	my $value = shift;
	my ($command, $arguments) = @{$value};
	return Build::Graph::Action->new(command => $command, arguments => $arguments);
};

sub _coerce_actions {
	my $value = shift;
	return [ map { ref() ? $from_array->($_) : $from_string->($_) } @{$value} ];
}

sub actions {
	my $self = shift;
	return @{ $self->{actions} };
}

sub run {
	my ($self, $graph, $options) = @_;
	for my $action ($self->actions) {
		my $command = $action->command;
		my $callback = $graph->commandset->get($command) or Carp::croak("Command $command doesn't exist");
		$callback->($graph->info_class->new(%{$options}, name => $self->name, arguments => $action->arguments, graph => $graph, node => $self));
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

