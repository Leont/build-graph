package Build::Graph::Group;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		module   => $args{module}   || Carp::croak('No module given'),
		elements => $args{elements} || {},
	}, $class;
}

sub module {
	my $self = shift;
	return $self->{module};
}

sub get {
	my ($self, $command) = @_;
	return $self->{elements}{$command};
}

sub add {
	my ($self, %elements) = @_;
	while (my ($key, $action) = each %elements) {
		$self->{elements}{$key} = $action;
	}
	return;
}

sub all {
	my $self = shift;
	return keys %{ $self->{elements} };
}

1;
