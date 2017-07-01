package Build::Graph::Namespace;

use strict;
use warnings;

use Build::Graph::Callable::Function;

use Carp qw//;
use Scalar::Util qw//;

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		type  => $args{type},
		graph => $args{graph},
	}, $class;
	Scalar::Util::weaken($self->{graph});
	return $self;
}

sub add {
	my ($self, $name, $callback, $opts) = @_;
	Carp::croak("\u$self->{type} $name is already defined") if exists $self->{trans}{$name};

	my $callable = Scalar::Util::blessed($callback) ? $callback : Build::Graph::Callable::Function->new(graph => $self->{graph}, callback => $callback);
	$self->{commands}{$name} = $callable;
	return;
}

sub eval {
	my ($self, $opt, $name, @arguments) = @_;
	if (my $callable = $self->{commands}{$name}) {
		return $callable->call($opt, @arguments);
	}
	else {
		Carp::croak("No such $self->{type} $name");
	}
}

1;
