package Basic;

use strict;
use warnings;

use base 'Build::Graph::Role::CommandSet';

use Carp qw/croak/;

use File::Path 'mkpath';
use File::Basename 'dirname';

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{next_is} = $args{next_is};
	$self->{next_is_ref} = do { no strict 'refs'; \&{ $args{next_is} } };
	return $self;
}

sub get_action {
	my ($self, $name) = @_;
	return {
		'spew' => sub {
				my ($target, $outhandle, $source) = @_;
				$self->{next_is_ref}->($target);
				print $outhandle $source;
		},
		'noop' => $self->{next_is_ref},
	}->{$name};
}

sub get_transformation {
	my ($self, $name) = @_;
	return {
		's-ext' => sub {
			my ($orig, $repl, $source) = @_;
			$source =~ s/(?<=\.)\Q$orig\E\z/$repl/;
			return $source;
		}
	}->{$name};
}

sub to_hashref {
	my $self = shift;
	my $ret = $self->SUPER::to_hashref;
	$ret->{next_is} = $self->{next_is};
	return $ret;
}

1;
