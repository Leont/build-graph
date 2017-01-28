package Build::Graph::Node::File;

use strict;
use warnings;

use base 'Build::Graph::Role::Node';

sub run {
	my ($self, $arguments) = @_;

	my @dependencies = $self->dependencies;

	my $filename = $self->name;

	my $graph = $self->{graph};
	my @files = grep { $graph->_get_node($_) && $graph->_get_node($_)->isa(__PACKAGE__) } @dependencies;

	# return if all of the source files are older than the targed files
	return if -e $filename and sub { -d or -M $filename <= -M or return 0 for @files; 1 }->();

	my %options = (
		%{$arguments},
		target => $filename,
		dependencies => \@dependencies,
		source => $dependencies[0],
		dirname => File::Basename::dirname($filename),
		basename => File::Basename::basename($filename),
	);
	File::Path::mkpath($options{dirname}, 0, 0755) if not -d $options{dirname};
	@options{'handle', 'out'} = File::Temp::tempfile(".$options{basename}.tempXXXX", DIR => $options{dirname}, UNLINK => 1);

	if ($self->{actions}) {
		unlink $filename if -e $filename;
		for my $action (@{ $self->{actions} }) {
			$self->execute($action, \%options);
		}
		rename $options{out}, $filename if !-e $filename;
	}
	else {
		Carp::croak("No action for $filename");
	}
	return;
}

1;

#ABSTRACT: A class for file nodes
