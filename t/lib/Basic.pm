package Basic;

use strict;
use warnings;

use Carp qw/croak/;

use File::Path 'mkpath';
use File::Basename 'dirname';
use Scalar::Util 'weaken';

sub add_to {
	my ($class, $graph, %args) = @_;
	$graph->actions->add('spew' => sub {
		my ($target, $outhandle, $source) = @_;
		main::next_is($target);
		print $outhandle $source;
	});
	$graph->actions->add('noop' => \&main::next_is);
	$graph->transformations->add('s-ext' => sub {
		my ($orig, $repl, $source) = @_;
		$source =~ s/(?<=\.)\Q$orig\E\z/$repl/;
		return $source;
	});

	return;
}

1;
