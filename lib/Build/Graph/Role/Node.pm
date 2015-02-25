package Build::Graph::Role::Node;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $ret = bless {
		graph        => $args{graph}        || Carp::croak('No graph given'),
		name         => $args{name}         || Carp::croak('No name given'),
		dependencies => $args{dependencies} || [],
		action       => $args{action},
	}, $class;
	Scalar::Util::weaken($ret->{graph});
	return $ret;
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

sub run {
	my ($self, $options) = @_;
	my @parts = @{ $self->{action} || [] } or return;
	my ($callback, @arguments) = $self->{graph}->resolve(@parts) or return;
	$callback->($self->{graph}->info_class->new(%{$options}, name => $self->name, arguments => \@arguments));
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

# ABSTRACT: A role shared by different Node types

=attr dependencies

=attr action

=method to_hashref

