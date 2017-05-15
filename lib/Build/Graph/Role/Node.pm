package Build::Graph::Role::Node;

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

sub execute {
	my ($self, $action, $options) = @_;
	return $self->{graph}->eval_action($options, @{$action});
}

sub to_hashref {
	my $self                = shift;
	my %ret;
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
