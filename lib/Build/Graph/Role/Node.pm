package Build::Graph::Role::Node;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		name         => $args{name}         || Carp::croak('No name given'),
		dependencies => $args{dependencies} || [],
		action       => $args{action},
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

sub action {
	my $self = shift;
	return @{ $self->{action} };
}

sub run {
	my ($self, $graph, $options) = @_;
	return if not $self->{action};
	my ($command, @raw_args) = @{ $self->{action} };
	my $callback = $graph->commandset->get($command) or Carp::croak("Command $command doesn't exist");
	my @arguments = $graph->expand(@raw_args);
	$callback->($graph->info_class->new(%{$options}, name => $self->name, arguments => \@arguments, graph => $graph, node => $self));
	return;
}

sub to_hashref {
	my $self         = shift;
	my @dependencies = $self->dependencies;
	my %ret          = (class => ref $self);
	$ret{dependencies} = \@dependencies  if @dependencies;
	$ret{action}       = $self->{action} if $self->{action};
	return \%ret;
}

1;

=attr dependencies

=attr action

=method to_hashref

