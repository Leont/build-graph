package Build::Graph::Role::FileSet;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name         => $args{name} || Carp::croak('No name given'),
		graph        => $args{graph},
		files        => [],
		substs       => [],
	}, $class;
	Scalar::Util::weaken($self->{graph});
	return $self;
}

sub files {
	my $self = shift;
	return @{ $self->{files} };
}

sub on_file {
	my ($self, $sub) = @_;
	push @{ $self->{substs} }, $sub;
	for my $file (@{ $self->{files} }) {
		$sub->process($file);
	}
	return;
}

1;

# ABSTRACT: A role shared by sets of files (e.g. wildcards and substitutions)
