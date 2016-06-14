package Build::Graph::Variable::Subst;

use strict;
use warnings;

use base 'Build::Graph::Role::Variable';

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{name}              = $args{name}            || Carp::croak('No name given');
	@{ $self->{trans}        } = @{ $args{trans}        || Carp::croak('No trans given')  };
	@{ $self->{action}       } = @{ $args{action}       }  if $args{action};
	@{ $self->{dependencies} } = @{ $args{dependencies} }  if $args{dependencies};
	$self->{graph}             = $args{graph}           || Carp::croak('No graph given');
	Scalar::Util::weaken($self->{graph});
	return $self;
}

sub process {
	my ($self, $source) = @_;

	my ($command, @arguments) = $self->{graph}->expand({ source => $source }, @{ $self->{trans} });
	my ($plugin_name, $subcommand) = split m{/}, $command, 2;
	my $plugin = $self->{graph}->lookup_plugin($plugin_name) or Carp::croak("No such plugin $plugin_name");
	my $target = $plugin->get_transformation($subcommand)->(@arguments);

	$self->{graph}->add_file($target, dependencies => [ $source, @{ $self->{dependencies} || [] } ], action => $self->{action}) if $self->{action};
	$self->add_entries($target);
	return;
}

sub to_hashref {
	my $self = shift;
	my $ret  = $self->SUPER::to_hashref;
	@{ $ret->{trans} } = @{ $self->{trans} };
	@{ $ret->{action} } = @{ $self->{action} } if $self->{action};
	@{ $ret->{dependencies} } = @{ $self->{dependencies} } if $self->{dependencies};
	return $ret;
}

1;

#ABSTRACT: Substitutions on filenames in a Build::Graph graph
