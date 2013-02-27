package Build::Graph::Node;
use Moo;

use Build::Graph::Action;

use File::Basename qw//;
use File::Path qw//;

has phony => (
	is       => 'ro',
	required => 1,
);

has need_dir_override => (
	is        => 'rw',
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

has _dependencies => (
	is       => 'ro',
	default  => sub { [] },
	init_arg => 'dependencies',
);

sub dependencies {
	my $self = shift;
	return @{ $self->_dependencies };
}

sub add_dependencies {
	my ($self, @dependencies) = @_;
	push @{ $self->_dependencies }, @dependencies;
	return;
}

my $from_string = sub {
	my $value = shift;
	return Build::Graph::Action->new(command => $value);
};
my $from_hashref = sub {
	my $value = shift;
	return Build::Graph::Action->new(%{$value});
};

has _actions => (
	is       => 'ro',
	default  => sub { [] },
	init_arg => 'actions',
	coerce   => sub {
		my $value = shift;
		my $type  = ref $value;
		if ($type eq 'Build::Graph::Action') {
			return [$value];
		}
		elsif ($type eq 'ARRAY') {
			return [ map { ref() ? $from_hashref->($_) : $from_string->($_) } @{$value} ];
		}
		elsif ($type eq 'HASH') {
			return [ $from_hashref->($value) ];
		}
		elsif ($type eq '') {
			return [ $from_string->($value) ];
		}
	},
);

sub actions {
	my $self = shift;
	return @{ $self->_actions };
}

sub to_hashref {
	my $self = shift;
	return {
		phony        => $self->phony,
		dependencies => $self->_dependencies,
		actions      => [ map { $_->to_hashref } $self->actions ],
		$self->_has_need_dir_override ? (need_dir => $self->need_dir_override) : (),
	};
}

1;

#ABSTRACT: A dependency graph node

=attr phony

=attr dependencies

=attr action

=method to_hashref

=method need_dir

=method make_dir
