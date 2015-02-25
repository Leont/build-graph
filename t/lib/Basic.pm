package Basic;

use strict;
use warnings;

use parent 'Build::Graph::Role::CommandProvider';

use Carp qw/croak/;

use File::Path 'mkpath';
use File::Basename 'dirname';

sub _get_commands {
	my ($class, %args) = @_;
	my $next_is = $args{next_is};
	return {
		'spew' => sub { my $info = shift; $next_is->($info->name); spew($info->name, $info->arguments) },
		'poke' => sub { $next_is->('poke') },
		'noop' => sub { $next_is->($_[0]->name) },
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
