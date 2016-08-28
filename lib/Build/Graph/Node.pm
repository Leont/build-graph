package Build::Graph::Node;

use strict;
use warnings;

use Carp ();
use File::Basename ();
use File::Path ();
use File::Temp ();
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
	if ($args{action_list} && @{ $args{action_list} } > 0) {
		@{ $self->{actions} } = map { [@$_] } @{ $args{action_list} };
	}
	elsif ($args{action}) {
		@{ $self->{actions} } = [ @{ $args{action} } ];
	}
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
	if (!$self->{phony}) {
		$options{dirname} = File::Basename::dirname($options{target});
		File::Path::mkpath($options{dirname}, 0, 0755) if not -d $options{dirname};
		my $basename = File::Basename::basename($options{target});
		@options{'handle', 'out'} = File::Temp::tempfile(".$basename.tempXXXX", DIR => $options{dirname}, UNLINK => 1);
	}
	if ($self->{actions}) {
		for my $action (@{ $self->{actions} }) {
			my ($command, @arguments) = $self->{graph}->expand(\%options, @{ $action });
			my ($plugin_name, $subcommand) = split m{/}, $command, 2;
			my $plugin = $self->{graph}->lookup_plugin($plugin_name) or Carp::croak("No such plugin $plugin_name");
			my $callback = $plugin->get_action($subcommand) or Carp::croak("No callback $subcommand in $plugin_name");
			unlink $options{target} if !$self->{phony} && -e $options{target};
			$callback->(@arguments);
			rename $options{out}, $options{target} if !$self->{phony} && !-e $options{target};
		}
	}
	else {
		Carp::croak("No action for $self->{name}") if !$self->{phony};
	}
	return;
}

sub to_hashref {
	my $self                = shift;
	my %ret;
	$ret{phony}             = 1 if $self->{phony};
	@{ $ret{dependencies} } = @{ $self->{dependencies} } if $self->{dependencies};
	if ($self->{actions}) {
		if (@{ $self->{actions} } == 1) {
			@{ $ret{action} } = @{ $self->{actions}[0] };
		}
		else {
			@{ $ret{action_list} } = map { [@$_] } @{ $self->{actions} };
		}
	}
	return \%ret;
}

1;

# ABSTRACT: A role shared by different Node types

=attr dependencies

=attr action

=method to_hashref
