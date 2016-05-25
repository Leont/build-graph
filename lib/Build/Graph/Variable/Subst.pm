package Build::Graph::Variable::Subst;

use strict;
use warnings;

use base 'Build::Graph::Role::Variable';

use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{trans}        = $args{trans}        || Carp::confess('No trans given');
	$self->{action}       = $args{action}       || Carp::croak('No action given');
	$self->{dependencies} = $args{dependencies} || [];
	return $self;
}

sub process {
	my ($self, $source) = @_;

	my ($command, @arguments) = $self->{graph}->expand({ source => $source }, @{ $self->{trans} });
	my ($plugin_name, $subcommand) = split m{/}, $command, 2;
	my $plugin = $self->{graph}->lookup_plugin($plugin_name) or Carp::croak("No such plugin $plugin_name");
	my $target = $plugin->run_trans($subcommand, @arguments) or Carp::croak("No such transformation $subcommand in plugin " . $plugin->name);

	$self->{graph}->add_file($target, dependencies => [ $source, @{ $self->{dependencies} } ], action => $self->{action}) if $self->{action};
	push @{ $self->{entries} }, $target;
	$self->trigger($target);
	return;
}

sub to_hashref {
	my $self = shift;
	my $ret  = $self->SUPER::to_hashref;
	@{$ret}{qw/trans action/} = @{$self}{qw/trans action/};
	$ret->{dependencies} = $self->{dependencies} if @{ $self->{dependencies} };
	return $ret;
}

1;

#ABSTRACT: Substitutions on filenames in a Build::Graph graph
