package Build::Graph::CommandLoader;

use strict;
use warnings;

use parent 'Build::Graph::Role::Loader';

sub load {
	my ($self, $module, %args) = @_;
	$self->load_module($module);
	my $ret = $module->new(%args);
	$self->graph->plugins->add_plugin($args{name}, $ret);
	return $ret;
}

1;


