package Build::Graph::Subst;

use strict;
use warnings;

use parent 'Build::Graph::Role::FileSet';

use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{subst}        = $args{subst}  || Carp::croak('No subst given');
	$self->{action}       = $args{action} || Carp::croak('No action given');
	$self->{dependencies} = $args{dependencies} || [];
	return $self;
}

sub process {
	my ($self, $source) = @_;

	my ($command, @args) = @{ $self->{subst} };
	my $subst_action = $self->{graph}->plugins->get_subst($command) or die "No such subst $command";
	my $target = $subst_action->(map { $self->{graph}->expand($_, { source => $source }) } @args);

	$self->{graph}->add_file($target, dependencies => [ $source, @{ $self->{dependencies} } ], action => $self->{action});
	$_->process($target) for @{ $self->{substs} };
	push @{ $self->{files} }, $target;
	$self->{graph}->add_variable($self->{name}, $target);
	return $target;
}

1;

#ABSTRACT: Substitutions on filenames in a Build::Graph graph
