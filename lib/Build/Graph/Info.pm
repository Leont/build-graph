package Build::Graph::Info;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		name      => $args{name} || Carp::croak('No name given'),
		arguments => $args{arguments},
		node      => $args{node} || Carp::croak('No node given'),
		graph     => $args{graph} || Carp::croak('No graph given'),
	}, $class;
}

for my $attr (qw/name node graph/) {
	no strict 'refs';
	*{$attr} = sub {
		my $self = shift;
		return $self->{$attr};
	};
}

sub arguments {
	my $self = shift;
	return @{ $self->{arguments} };
}

1;

#ABSTRACT: Runtime information for actions

