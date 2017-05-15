package Build::Graph::Callable::Function;

use strict;
use warnings;

use base 'Build::Graph::Role::Callable';
use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{callback} = $args{callback} || Carp::croak('No callback given');
	return $self;
}

sub call {
	my ($self, $opt, @arguments) = @_;
	my @expanded = $self->{graph}->expand($opt, @arguments);
	return $self->{callback}->(@expanded);
}

# ABSTRACT: An implementation of Callable, implementing normal functions.

1;
