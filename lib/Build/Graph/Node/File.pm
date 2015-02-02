package Build::Graph::Node::File;

use strict;
use warnings;

use File::Basename qw//;
use File::Path qw//;

use parent 'Build::Graph::Role::Node';

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{weak} = $args{weak} || 0,
	$self->{needs_dir_override} = $args{needs_dir_override} if defined $args{needs_dir_override};
	return $self;
}

sub weak {
	my $self = shift;
	return $self->{weak};
}

sub run {
	my ($self, $graph, $options) = @_;
	my $filename = $self->name;

	my @files = grep { $graph->get_node($_) && $graph->get_node($_)->phony || -e $_ } sort $self->dependencies;
	
	return if -e $filename and sub { -d $_ or -M $filename <= -M $_ or return 0 for @files; 1 }->();

	File::Path::mkpath(File::Basename::dirname($filename)) if exists $self->{need_dir_override} ? $self->{need_dir_override} : 1;

	$self->SUPER::run($graph, $options);

	return;
}

sub to_hashref {
	my ($self) = @_;

	return {
		%{ $self->SUPER::to_hashref },
		exists $self->{need_dir_override} ? (need_dir => $self->{need_dir_override}) : (),
		(weak => 1) x!! $self->weak,
	};
}

sub phony { 0 }

1;

#ABSTRACT: A dependency graph node for file targets

=method make_dir

