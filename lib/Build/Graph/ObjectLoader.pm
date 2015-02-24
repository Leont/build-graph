package Build::Graph::ObjectLoader;

use strict;
use warnings;

use parent 'Build::Graph::Role::Loader';

sub load {
	my ($self, $module, @args) = @_;
	$self->load_module($module);
	return $module->new(@args);
}

1;


