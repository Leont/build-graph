package Build::Graph::Subst;

use strict;
use warnings;

use parent 'Build::Graph::Role::FileSet';

use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{graph}        =  $args{graph},
	$self->{subst}        =  $args{subst} || Carp::croak('No subst given'),
	$self->{actions}      =  $args{actions} || Carp::croak('No actions given'),
	$self->{dependencies} =  $args{dependencies} || [],
	$self->{dependents}   =  $args{dependents},
	return $self;
}

sub process {
	my ($self, $source) = @_;
	my $target = $self->{subst}->($source);
	my $action = $self->{actions}->($target, $source);
	$self->{graph}->add_file($target, dependencies => [ $source, @{ $self->{dependencies} } ], actions => $action);
	if ($self->{dependents}) {
		my @dependents = ref $self->{dependents} ? @{ $self->{dependents} } : $self->{dependents};
		for my $dependent (@dependents) {
			$self->{graph}->get_node($dependent)->add_dependencies($target);
		}
	}
	my @subst = map { $_->process($target) } @{ $self->{substs} };
	push @{ $self->{files}{$target} }, @subst;
	return $target;
}

1;

#ABSTRACT: Substitutions on filenames in a Build::Graph graph
