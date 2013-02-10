package Build::Graph::Dependencies;
use Any::Moose;
use Any::Moose 'Util::TypeConstraints';
use List::MoreUtils qw//;
use Carp qw//;

coerce 'Build::Graph::Dependencies', from 'HashRef', via {
	my %deps = %{$_};
	for my $value (values %deps) {
		next if ref $value;
		$value = defined $value ? [$value] : [];
	}
	Build::Graph::Dependencies->new(dependencies => \%deps);
};
coerce 'Build::Graph::Dependencies', from 'ArrayRef', via {
	my %deps = map { $_ => [] } @{$_};
	Build::Graph::Dependencies->new(dependencies => \%deps);
};

has _dependencies => (
	is       => 'ro',
	isa      => 'HashRef[ArrayRef[Str]]',
	default  => sub { {} },
	init_arg => 'dependencies',
	traits   => ['Hash'],
	handles  => {
		all    => 'keys',
		_kv    => 'kv',
		_get   => 'get',
		_set   => 'set',
		delete => 'delete',
		_flat  => 'elements',
	},
);

sub types_for {
	my ($self, $name) = @_;
	my $types = $self->_get($name) or Carp::croak("$name is not a dependency of this node");
	return @{$types};
}

sub with_type {
	my ($self, $wanted_type) = @_;
	my @ret;
	for my $pair ($self->_kv) {
		my ($name, $types) = @{$pair};
		push @ret, $name if List::MoreUtils::any { $_ eq $wanted_type } @{$types};
	}
	return @ret;
}

sub add {
	my ($self, $name, @types) = @_;
	push @{ $self->_get($name) || $self->_set($name, []) }, @types;
	return;
}

sub remove_type {
	my ($self, $name, $type) = @_;
	my $list = $self->_get($name) or return;
	@{$list} = grep { $_ ne $type } @{$list};
	$self->delete($name) if not @{$list};
	return;
}

sub to_hashref {
	my $self = shift;
	return { $self->_flat };
}

1;

#ABSTRACT: A dependency node's set of dependencies

=method all()

Returns all dependencies, in an indeterminate order.

=method add($dep, @types)

Creates a dependency on $dep, and adds C<@types> to that.

=method delete($dep)

Deletes the dependency C<$dep>.

=method with_type($type)

Returns all dependencies with a certain C<$type>.

=method to_hashref()

Converts the dependencies to a 'simple' hashref representation.

=method types_for($dep)

Return all types for $dep.

=method remove_type($dep, $type)

Removes a type from a dependency.
