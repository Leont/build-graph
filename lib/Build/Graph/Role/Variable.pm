package Build::Graph::Role::Variable;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	my $self = bless {
		name       => $args{name}       || Carp::croak('No name given'),
		entries    => $args{entries}    || [],
		dependents => $args{dependents} || [],
	}, $class;
	return $self;
}

sub entries {
	my $self = shift;
	return @{ $self->{entries} };
}

sub add_dependent {
	my ($self, $dep) = @_;
	push @{ $self->{dependents} }, $dep;
	for my $file (@{ $self->{entries} }) {
		$dep->add_input($file);
	}
	return;
}

sub pass_on {
	my ($self, $entry) = @_;
	for my $dependent (@{ $self->{dependents} }) {
		$dependent->add_input($entry);
	}
	return;
}

sub to_hashref {
	my $self = shift;
	my %ret;
	$ret{type}            = lc +(ref($self) =~ /^Build::Graph::Variable::(\w+)$/)[0];
	@{ $ret{entries}    } = @{ $self->{entries} } if @{ $self->{entries} };
	@{ $ret{dependents} } = map { $_->{name} } @{ $self->{dependents} } if @{ $self->{dependents} };
	return \%ret;
}

1;

# ABSTRACT: A role shared by sets of entries (e.g. pattern and substitutions)
