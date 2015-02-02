#! perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Differences;

use File::Spec::Functions qw/catfile/;
use File::Basename qw/dirname/;
use File::Path qw/mkpath rmtree/;

use Build::Graph;
use Build::Graph::CommandSet;

use lib 't/lib';

my $graph = Build::Graph->new;
$graph->commandset->load('Core');

my $dirname = '_testing';
END { rmtree $dirname if defined $dirname }
$SIG{INT} = sub { rmtree $dirname; die "Interrupted!\n" };

my $source1_filename = catfile($dirname, 'source1');
$graph->add_file($source1_filename, actions => [ 'basic/poke', { command => 'basic/spew', arguments => 'Hello' } ]);

my $source2_filename = catfile($dirname, 'source2');
$graph->add_file($source2_filename, actions => { command => 'basic/spew', arguments => 'World' }, dependencies => [ $source1_filename ]);

$graph->add_phony('build', actions => 'basic/noop', dependencies => [ $source1_filename, $source2_filename ]);
$graph->add_phony('test', actions => 'basic/noop', dependencies => [ 'build' ]);
$graph->add_phony('install', actions => 'basic/noop', dependencies => [ 'build' ]);

my @sorted = $graph->_sort_nodes('build');

is_deeply \@sorted, [ $source1_filename, $source2_filename, 'build' ], 'topological sort is ok';

my @runs     = qw/build test install/;
my %expected = (
	build => [
		[qw{poke _testing/source1 _testing/source2 build}],
		[qw/build/],

		sub { rmtree $dirname },
		[qw{poke _testing/source1 _testing/source2 build}],
		[qw/build/],

		sub { unlink $source2_filename or die "Couldn't remove $source2_filename: $!" },
		[qw{_testing/source2 build}],
		[qw/build/],

		sub { unlink $source1_filename; sleep 1; },
		[qw{poke _testing/source1 _testing/source2 build}],
		[qw/build/],
	],
	test    => [
		[qw{poke _testing/source1 _testing/source2 build test}],
		[qw/build test/],
	],
	install => [
		[qw{poke _testing/source1 _testing/source2 build install}],
		[qw/build install/],
	],
);

my $run;
our @got;
sub next_is {
	my $gotten = shift;
	push @got, $gotten;
}

my $clone = Build::Graph->load($graph->to_hashref);

my $is_clone = 0;
my @desc = qw/original clone/;
for my $current ($graph, $clone) {
	for my $runner (sort keys %expected) {
		rmtree $dirname;
		$run = $runner;
		my $count = 1;
		for my $runpart (@{ $expected{$runner} }) {
			if (ref($runpart) eq 'CODE') {
				$runpart->();
			}
			else {
				my @expected = map { catfile(File::Spec::Unix->splitdir($_)) } @{$runpart};
				local @got;
				$graph->run($run, verbosity => 1);
				eq_or_diff \@got, \@expected, "\@got is @expected in run $run-$desc[$is_clone]-$count";
				$count++;
			}
		}
	}
	$is_clone++;
}

done_testing();

