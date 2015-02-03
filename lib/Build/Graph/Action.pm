package Build::Graph::Action;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless {
		command => $args{command} || '',
		(arguments => $args{arguments}) x!! defined $args{arguments},
	}, $class;
}

sub command {
	my $self = shift;
	return $self->{command};
}
sub arguments {
	my $self = shift;
	return $self->{arguments};
}

sub to_hashref {
	my $self = shift;
	return [
		$self->{command},
		($self->{arguments}) x!! defined $self->{arguments},
	];
}

1;

#ABSTRACT: A Build::Graph action

=attr command

=attr arguments

=method to_hashref
