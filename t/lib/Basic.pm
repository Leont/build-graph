package Basic;

use strict;
use warnings;

use base 'Build::Graph::Role::CommandSet';

use Carp qw/croak/;

use File::Path 'mkpath';
use File::Basename 'dirname';
use Scalar::Util 'weaken';

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{graph}->actions->add('spew' => sub {
		my ($target, $outhandle, $source) = @_;
		main::next_is($target);
		print $outhandle $source;
	});
	$self->{graph}->actions->add('noop' => \&main::next_is);
	$self->{graph}->transformations->add('s-ext' => sub {
		my ($orig, $repl, $source) = @_;
		$source =~ s/(?<=\.)\Q$orig\E\z/$repl/;
		return $source;
	});

	return $self;
}

sub eval_transformation {
	my ($self, $name, @arguments) = @_;
	my $sub = {
	}->{$name};
	return $sub->(@arguments);
}

sub to_hashref {
	my $self = shift;
	my $ret = $self->SUPER::to_hashref;
	return $ret;
}

1;
