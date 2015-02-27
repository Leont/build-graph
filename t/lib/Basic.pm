package Basic;

use strict;
use warnings;

use parent 'Build::Graph::Role::CommandProvider';

use Carp qw/croak/;

use File::Path 'mkpath';
use File::Basename 'dirname';

sub _get_commands {
	my ($class, %args) = @_;
	return {
		'spew' => sub { my ($target, $source) = @_; $args{next_is}->($target); spew($target, $source) },
		'noop' => $args{next_is},
	};
}

sub _get_substs {
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
