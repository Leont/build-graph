package Build::Graph::Role::Entries;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name         => $args{name} || Carp::croak('No name given'),
		graph        => $args{graph},
		entries      => [],
		substs       => [],
	}, $class;
	Scalar::Util::weaken($self->{graph});
	return $self;
}

sub entries {
	my $self = shift;
	return @{ $self->{entries} };
}

sub on_file {
	my ($self, $sub) = @_;
	push @{ $self->{substs} }, $sub;
	for my $file (@{ $self->{entries} }) {
		$sub->process($file);
	}
	return;
}

1;

# ABSTRACT: A role shared by sets of entries (e.g. wildcards and substitutions)
