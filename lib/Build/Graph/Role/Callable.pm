package Build::Graph::Role::Callable;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		graph => $args{graph} || Carp::croak('No graph given'),
	}, $class;
}

sub call;

#ABSTRACT: An interface for callable actions

1;
