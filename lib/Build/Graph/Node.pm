package Build::Graph::Node;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		graph        => $args{graph}        || Carp::croak('No graph given'),
		name         => $args{name}         || Carp::croak('No name given'),
		phony        => !!$args{phony},
	}, $class;
	Scalar::Util::weaken($self->{graph});
	@{ $self->{dependencies} } = @{ $args{dependencies} } if $args{dependencies};
	@{ $self->{action}       } = @{ $args{action} } if $args{action};
	return $self;
}

sub name {
	my $self = shift;
	return $self->{name};
}

sub dependencies {
	my $self = shift;
	return $self->{graph}->expand({ target => $self->name }, @{ $self->{dependencies} || [] });
}

sub run {
	my ($self, $arguments) = @_;

	my @dependencies = $self->dependencies;

	if (!$self->{phony}) {
		my $filename = $self->name;

		my $graph = $self->{graph};
		my @files = grep { $graph->_get_node($_) && !$graph->_get_node($_)->{phony} } @dependencies;

		return if -e $filename and sub { -d or -M $filename <= -M or return 0 for @files; 1 }->();
	}

	my %options = (%{$arguments}, target => $self->{name}, dependencies => \@dependencies, source => $dependencies[0]);
	my ($command, @arguments) = $self->{graph}->expand(\%options, @{ $self->{action} || [] }) or do {
		return if $self->{phony};
		Carp::croak("No action for $self->{name}");
	};

	my ($plugin_name, $subcommand) = split m{/}, $command, 2;
	my $plugin = $self->{graph}->lookup_plugin($plugin_name) or Carp::croak("No such plugin $plugin_name");
	return $plugin->get_command($subcommand)->(@arguments)
}

sub to_hashref {
	my $self           = shift;
	my %ret;
	$ret{phony}             = 1 if $self->{phony};
	@{ $ret{dependencies} } = @{ $self->{dependencies} } if $self->{dependencies};
	@{ $ret{action} }       = @{ $self->{action} } if $self->{action};
	return \%ret;
}

1;

# ABSTRACT: A role shared by different Node types

=attr dependencies

=attr action

=method to_hashref

