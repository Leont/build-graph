package Build::Graph::Info;

use strict;
use warnings;

use Carp ();

sub new {
	my ($class, %args) = @_;
	return bless {
		target    => $args{target} || Carp::croak('No target given'),
		arguments => $args{arguments},
	}, $class;
}

sub target {
	my $self = shift;
	return $self->{target};
}

sub arguments {
	my $self = shift;
	return @{ $self->{arguments} };
}

1;

#ABSTRACT: Runtime information for actions

