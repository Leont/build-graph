package Build::Graph::Role::FileSet;

use strict;
use warnings;

sub new {
	my ($class, %args) = @_;
	return bless {
#		graph        => $args{graph},
		files        => {},
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
	for my $file (keys %{ $self->{files} }) {
		$sub->process($file);
	}
	return;
}

1;
