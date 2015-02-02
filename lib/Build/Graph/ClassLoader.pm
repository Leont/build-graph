package Build::Graph::ClassLoader;

use strict;
use warnings;

use parent 'Build::Graph::Role::Loader';

use Module::Runtime ();

sub load {
	my ($self, $module) = @_;
	Module::Runtime::require_module($module);
	return $module;
}

1;

