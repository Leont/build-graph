package Build::Graph::Variable::Subst;

use strict;
use warnings;

use base 'Build::Graph::Role::Variable';

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	if ($args{trans_list}) {
		@{ $self->{trans} } = map { [@$_] } @{ $args{trans_list} };
	}
	elsif ($args{trans}) {
		@{ $self->{trans} } = [ @{ $args{trans} } ];
	}
	else {
		Carp::croak('No trans given');
	}
	if ($args{action_list}) {
		@{ $self->{actions} } = map { [@$_] } @{ $args{action_list} };
	}
	elsif ($args{action}) {
		@{ $self->{actions} } = [ @{ $args{action} } ];
	}
	@{ $self->{dependencies} } = @{ $args{dependencies} }  if $args{dependencies};
	$self->{graph}             = $args{graph}           || Carp::croak('No graph given');
	Scalar::Util::weaken($self->{graph});
	return $self;
}

sub _serialize_actions {
	my $self = shift;
	if ($self->{actions}) {
		if (@{ $self->{actions} } == 1) {
			return action => [ @{ $self->{actions}[0] } ];
		}
		else {
			return action_list => [ map { [@$_] } @{ $self->{actions} } ];
		}
	}
	return;
}

sub add_input {
	my ($self, $source) = @_;

	my $target = $source;
	for my $trans (@{ $self->{trans} }) {
		$target = $self->{graph}->transformations->eval({ source => $self->{graph}->escape($target) }, @{ $trans });
	}

	$self->{graph}->add_file($target, dependencies => [ $self->{graph}->escape($source), @{ $self->{dependencies} || [] } ], $self->_serialize_actions);
	push @{ $self->{entries} }, $target;
	$self->pass_on($target);
	return;
}

sub to_hashref {
	my $self = shift;
	my $ret  = $self->SUPER::to_hashref;
	if ($self->{trans}) {
		if (@{ $self->{trans} } == 1) {
			@{ $ret->{trans} } = @{ $self->{trans}[0] };
		}
		else {
			@{ $ret->{trans_list} } = map { [@$_] } @{ $self->{trans} };
		}
	}
	if ($self->{actions}) {
		my ($key, $value) = $self->_serialize_actions;
		$ret->{$key} = $value;
	}
	@{ $ret->{dependencies} } = @{ $self->{dependencies} } if $self->{dependencies};
	return $ret;
}

1;

#ABSTRACT: Substitutions on filenames in a Build::Graph graph
