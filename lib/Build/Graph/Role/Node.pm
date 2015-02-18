package Build::Graph::Role::Node;

use strict;
use warnings;

use Carp ();

use Build::Graph::Action;

sub new {
	my ($class, %args) = @_;
	return bless {
		name         => $args{name}         || Carp::croak('No name given'),
		dependencies => $args{dependencies} || [],
		$args{action} ? (action => _coerce_action($args{action})) : (),
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

sub _coerce_action {
	my $value = shift;
	my ($command, @arguments) = @{$value};
	return Build::Graph::Action->new(command => $command, arguments => [ @arguments ]);
}

sub action {
	my $self = shift;
	return $self->{action};
}

sub run {
	my ($self, $graph, $options) = @_;
	my $action = $self->action;
	return if not $action;
	my $command = $action->command;
	my $callback = $graph->commandset->get($command) or Carp::croak("Command $command doesn't exist");
	my @arguments = $graph->expand($action->arguments);
	$callback->($graph->info_class->new(%{$options}, name => $self->name, arguments => \@arguments, graph => $graph, node => $self));
	return;
}

sub to_hashref {
	my $self         = shift;
	my @dependencies = $self->dependencies;
	my $action       = $self->action;
	my %ret          = (class => ref $self);
	$ret{dependencies} = \@dependencies      if @dependencies;
	$ret{action}       = $action->to_hashref if $action;
	return \%ret;
}

1;

=attr dependencies

=attr action

=method to_hashref

