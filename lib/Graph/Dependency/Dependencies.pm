package Graph::Dependency::Dependencies;
use Any::Moose;
use Any::Moose 'Util::TypeConstraints';

coerce 'Graph::Dependency::Dependencies', from 'HashRef[Str]', via { Graph::Dependency::Dependencies->new(dependencies => $_) };

has dependencies => (
	isa => 'HashRef[Str]',
	default => sub { {} },
	init_arg => 'dependencies',
	traits => ['Hash'],
	handles => {
		all  => 'keys',
		_kv  => 'kv',
		has  => 'count',
		get  => 'get',
		set  => 'set',
		delete => 'delete',
		_flat => 'elements',
		_types => 'values',
	},
);

sub types {
	my $self = shift;
	return List::MoreUtils::uniq($self->_types);
}

sub for_type {
	my ($self, $wanted_type) = @_;
	my @ret;
	for my $pair ($self->_kv) {
		my ($name, $type) = @{$pair};
		push @ret, $name if $type eq $wanted_type;
	}
	return @ret;
}

sub to_hashref {
	my $self = shift;
	return { $self->_flat_elements };
}

1;

__END__
