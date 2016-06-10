package Build::Graph::Role::Variable;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		entries => $args{entries} || [],
		substs  => $args{substs}  || [],
	}, $class;
	return $self;
}

sub entries {
	my $self = shift;
	return @{ $self->{entries} };
}

sub add_subst {
	my ($self, $sub) = @_;
	push @{ $self->{substs} }, $sub;
	for my $file (@{ $self->{entries} }) {
		$sub->process($file);
	}
	return;
}

sub add_entries {
	my ($self, @entries) = @_;
	push @{ $self->{entries} }, @entries;
	for my $entry (@entries) {
		for my $subst (@{ $self->{substs} }) {
			$subst->process($entry);
		}
	}
	return;
}

sub to_hashref {
	my $self = shift;
	my %ret;
	$ret{type}    = lc +(ref($self) =~ /^Build::Graph::Variable::(\w+)$/)[0];
	$ret{entries} = $self->{entries} if @{ $self->{entries} };
	$ret{substs}  = [ map { $_->{name} } @{ $self->{substs} } ] if @{ $self->{substs} };
	return \%ret;
}

1;

# ABSTRACT: A role shared by sets of entries (e.g. wildcards and substitutions)
