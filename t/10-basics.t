#! perl

use strict;
use warnings FATAL => 'all';

use Test::More;
BEGIN {
	*eq_or_diff = eval { require Test::Differences } ? \&Test::Differences::eq_or_diff : \&Test::More::is_deeply;
}

use File::Spec::Functions qw/catfile/;
use File::Basename qw/dirname/;
use File::Path qw/mkpath rmtree/;

use Build::Graph;

use lib 't/lib';

my $graph = Build::Graph->new;
$graph->load_plugin(basic => 'Basic', next_is => \&next_is);

my $dirname = '_testing';
END { rmtree $dirname if defined $dirname }
$SIG{INT} = sub { rmtree $dirname; die "Interrupted!\n" };

my $source1_filename = catfile($dirname, 'source1');
$graph->add_file($source1_filename, action => [ 'basic/spew', '$(target)', 'Hello' ]);

my $source2_filename = catfile($dirname, 'source2');
$graph->add_file($source2_filename, action => [ 'basic/spew', '$(target)', 'World' ], dependencies => [ $source1_filename ]);

my $wildcard = $graph->add_wildcard('foo-files', dir => $dirname, pattern => '*.foo');
$graph->add_subst('bar-files', $wildcard, subst => sub { (my $target = $_[0]) =~ s/\.foo/.bar/; return $target }, action => [ 'basic/spew', '$(target)', '$(source)' ]);

my $source3_foo = catfile($dirname, 'source3.foo');
$graph->add_file($source3_foo, action => [ 'basic/spew', '$(target)', 'foo' ]);
my $source3_bar = catfile($dirname, 'source3.bar');

$graph->add_phony('build', action => [ 'basic/noop', '$(target)' ], dependencies => [ $source1_filename, $source2_filename, $source3_bar ]);
$graph->add_phony('test', action => [ 'basic/noop', '$(target)' ], dependencies => [ 'build' ]);
$graph->add_phony('install', action => [ 'basic/noop', '$(target)' ], dependencies => [ 'build' ]);

my @sorted = $graph->_sort_nodes('build');

my @full = ($source1_filename, $source2_filename, $source3_foo, $source3_bar, 'build');

eq_or_diff(\@sorted, \@full, 'topological sort is ok');

my @runs     = qw/build test install/;
my %expected = (
	build => [
		[ @full ],
		[qw/build/],

		sub { rmtree $dirname },
		[ @full ],
		[qw/build/],

		sub { unlink $source2_filename or die "Couldn't remove $source2_filename: $!" },
		[qw{_testing/source2 build}],
		[qw/build/],

		sub { unlink $source3_foo; sleep 1 },
		[ $source3_foo, $source3_bar, 'build' ],
		[ 'build' ],

		sub { unlink $source3_bar },
		[ $source3_bar, 'build' ],
		[ 'build' ],

		sub { unlink $source1_filename; sleep 1; },
		[qw{_testing/source1 _testing/source2 build}],
		[qw/build/],
	],
	test    => [
		[ @full, 'test' ],
		[qw/build test/],
	],
	install => [
		[ @full, 'install' ],
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

