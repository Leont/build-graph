package Basic;

use strict;
use warnings;

use parent 'Build::Graph::Role::Plugin';

use Carp qw/croak/;

use File::Path 'mkpath';
use File::Basename 'dirname';

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	$self->{next_is} = $args{next_is};
	return $self;
}

sub get_commands {
	my ($self) = @_;
	return {
		'spew' => sub { my ($target, $source) = @_; $self->{next_is}->($target); spew($target, $source) },
		'noop' => $self->{next_is},
	};
}

sub get_substs {
	return {
		's-ext' => sub {
			my ($orig, $repl, $source) = @_;
			$source =~ s/(?<=\.)\Q$orig\E\z/$repl/;
			return $source;
		}
	};
}

sub spew {
	my ($filename, $content) = @_;
	mkpath(dirname($filename));
	open my $fh, '>', $filename or croak "Couldn't open file '$filename' for writing: $!\n";
	print $fh $content;
	close $fh or croak "couldn't close $filename: $!\n";
	return;
}

1;
