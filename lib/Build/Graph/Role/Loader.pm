package Build::Graph::Role::Loader;

use strict;
use warnings;

use Module::Runtime ();

sub new {
	my ($class, %args) = @_;
	return bless {
		graph => $args{graph} || Carp::croak(''),
	}, $class;
}

sub graph {
	my $self = shift;
	return $self->{graph};
}

sub load_module {
	my ($self, $module) = @_;
	Module::Runtime::require_module($module);
	return $module;
}

sub to_hashref {
	my $self = shift;
	return {
		module => ref($self),
	};
}

1;

