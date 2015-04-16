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
	return $self->{graph}->expand({}, @{ $self->{dependencies} });
}

sub add_dependencies {
	my ($self, @dependencies) = @_;
	push @{ $self->{dependencies} }, @dependencies;
	return;
}

sub run {
	my ($self, $more) = @_;
	my %options = (target => $self->{name}, dependencies => $self->{dependendies}, source => $self->{dependencies}[0], %{$more});
	my ($command, @arguments) = $self->{graph}->expand(\%options, @{ $self->{action} }) or return;

	my ($plugin_name, $subcommand) = split m{/}, $command, 2;
	my $plugin = $self->{graph}->lookup_plugin($plugin_name) or Carp::croak("No such plugin $plugin_name");
	return $plugin->run_command($subcommand, @arguments)
}

sub to_hashref {
	my $self         = shift;
	my @dependencies = @{ $self->{dependencies} };
	my %ret;
	$ret{type}         = lc +(ref($self) =~ /^Build::Graph::Node::(\w+)$/)[0];
	$ret{dependencies} = \@dependencies  if @dependencies;
	$ret{action}       = $self->{action} if $self->{action};
	return \%ret;
}

1;

# ABSTRACT: A role shared by different Node types

=attr dependencies

=attr action

=method to_hashref

