package Build::Graph::Info;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		name      => $args{name} || Carp::croak('No name given'),
		arguments => $args{arguments},
	}, $class;
}

sub name {
	my $self = shift;
	return $self->{name};
}

sub arguments {
	my $self = shift;
	return $self->{arguments};
}

1;

#ABSTRACT: Runtime information for actions

