package Build::Graph::Node;
use Any::Moose;

use Build::Graph::Dependencies;
use Build::Graph::Action;

use File::Basename qw//;
use File::Path qw//;

has phony => (
	is       => 'ro',
	isa      => 'Bool',
	required => 1,
);

has need_dir_override => (
	is        => 'rw',
	isa       => 'Bool',
	init_arg  => 'need_dir',
	predicate => '_has_need_dir_override',
);

sub need_dir {
	my $self = shift;
	return $self->need_dir_override if $self->_has_need_dir_override;
	return !$self->phony;
}

sub make_dir {
	my ($self, $name) = @_;
	File::Path::mkpath(File::Basename::dirname($name)) if $self->need_dir;
	return;
}

has dependencies => (
	is      => 'ro',
	isa     => 'Build::Graph::Dependencies',
	coerce  => 1,
	default => sub { Build::Graph::Dependencies->new },
);

has actions => (
	isa     => 'Build::Graph::ActionList',
	traits  => ['Array'],
	coerce  => 1,
	default => sub { [] },
	handles => { actions => 'elements' },
);

sub to_hashref {
	my $self = shift;
	return {
		phony        => $self->phony,
		dependencies => $self->dependencies->to_hashref,
		actions      => [ map { $_->to_hashref } $self->actions ],
		$self->_has_need_dir_override ? (need_dir => $self->need_dir_override) : (),
	};
}

1;

#ABSTRACT: A dependency graph node

__END__

=attr phony

=attr dependencies

=attr action

=method to_hashref

=method need_dir

=method make_dir
