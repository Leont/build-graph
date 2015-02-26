package Build::Graph::Subst;

use strict;
use warnings;

use parent 'Build::Graph::Role::FileSet';

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{graph}        = $args{graph};
	$self->{subst}        = $args{subst}  || Carp::croak('No subst given');
	$self->{action}       = $args{action} || Carp::croak('No action given');
	$self->{dependencies} = $args{dependencies} || [];
	Scalar::Util::weaken($self->{graph});
	return $self;
}

sub process {
	my ($self, $source) = @_;
	my $target = $self->{subst}->($source);
	my $action = [ @{ $self->{action} } ];
	$self->{graph}->add_file($target, dependencies => [ $source, @{ $self->{dependencies} } ], action => $action);
	my @subst = map { $_->process($target) } @{ $self->{substs} };
	push @{ $self->{files}{$target} }, @subst;
	return $target;
}

1;

#ABSTRACT: Substitutions on filenames in a Build::Graph graph
