package Build::Graph::Node::Phony;

use strict;
use warnings;

use base 'Build::Graph::Role::Node';

sub run {
	my ($self, $arguments) = @_;

	my %options = (
		%{$arguments},
		target => $self->{name},
		dependencies => [ $self->dependencies ],
	);

	if ($self->{actions}) {
		for my $action (@{ $self->{actions} }) {
			my ($callback, @arguments) = $self->lookup_command(\%options, @$action);
			$callback->(@arguments);
		}
	}
	return;
}


sub to_hashref {
	my $self = shift;
	my $ret = $self->SUPER::to_hashref;
	$ret->{phony} = 1;
	return $ret;
}

1;

#ABSTRACT: A class for phony nodes
