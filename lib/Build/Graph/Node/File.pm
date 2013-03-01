package Build::Graph::Node::File;
use Moo;

extends 'Build::Graph::Node::Phony';

use Carp qw//;
use File::Basename qw//;
use File::Path qw//;
use List::MoreUtils qw//;

has need_dir_override => (
	is        => 'rw',
	init_arg  => 'need_dir',
	predicate => '_has_need_dir_override',
);

my $newer = sub {
	my ($destination, $source) = @_;
	return 1 if not -e $source;
	return 0 if -d $source;
	return -M $destination > -M $source;
};

around run => sub {
	my ($orig, $self, $graph, $options) = @_;
	my $filename = $self->name;

	my @files = grep { $graph->get_node($_)->isa(__PACKAGE__) } sort $self->dependencies;
	return if -e $filename and not List::MoreUtils::any { $newer->($filename, $_) } @files;

	File::Path::mkpath(File::Basename::dirname($filename)) if $self->_has_need_dir_override ? $self->need_dir_override : 1;

	$self->$orig($graph, $options);

	return;
};

around to_hashref => sub {
	my ($orig, $self) = @_;

	return {
		%{ $self->$orig },
		$self->_has_need_dir_override ? (need_dir => $self->need_dir_override) : (),
	};
};

1;

#ABSTRACT: A dependency graph node for file targets

=method make_dir

