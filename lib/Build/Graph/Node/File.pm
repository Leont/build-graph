package Build::Graph::Node::File;
use Moo;

use File::Basename qw//;
use File::Path qw//;

has weak => (
	is      => 'ro',
	default => 0,
);

with 'Build::Graph::Role::Node';

has need_dir_override => (
	is        => 'rw',
	init_arg  => 'need_dir',
	predicate => '_has_need_dir_override',
);

around run => sub {
	my ($orig, $self, $graph, $options) = @_;
	my $filename = $self->name;

	my @files = grep { $graph->get_node($_) && $graph->get_node($_)->phony || -e $_ } sort $self->dependencies;
	
	return if -e $filename and sub { -d $_ or -M $filename <= -M $_ or return 0 for @files; 1 }->();

	File::Path::mkpath(File::Basename::dirname($filename)) if $self->_has_need_dir_override ? $self->need_dir_override : 1;

	$self->$orig($graph, $options);

	return;
};

around to_hashref => sub {
	my ($orig, $self) = @_;

	return {
		%{ $self->$orig },
		$self->_has_need_dir_override ? (need_dir => $self->need_dir_override) : (),
		(weak => 1) x!! $self->weak,
	};
};

sub phony { 0 }

1;

#ABSTRACT: A dependency graph node for file targets

=method make_dir

