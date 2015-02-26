package Build::Graph::Role::FileSet;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		name         => $args{name} || Carp::croak('No name given'),
		files        => [],
		substs       => [],
	}, $class;
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
