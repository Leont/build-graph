package Build::Graph::Callable::Macro;

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
	return $self->{callback}->($self->{graph}, $opt, @arguments);
}

# ABSTRACT: An implementation of Callable, implementing macros.

1;
