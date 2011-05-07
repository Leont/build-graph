#! perl

use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Differences;

use Carp qw/croak/;
use File::Spec::Functions qw/catfile/;
use File::Basename qw/dirname/;
use File::Path qw/mkpath rmtree/;
use List::MoreUtils qw/first_index/;

use Build::Graph;

my $graph = Build::Graph->new;
add_actions($graph);

sub add_actions {
	my $current = shift;
	$current->add_action('mkdir' => sub { next_is($_[0]); mkdir $_[0] });
	$current->add_action('spew' => sub { my ($name, $node) = @_; next_is($name); spew($name, $node->get_argument('content')) });
	$current->add_action('noop' => sub { next_is($_[0]) });
	return;
}

my $dirname = '_testing';
$graph->add_file($dirname, action => 'mkdir');
END { rmtree $dirname }
$SIG{INT} = sub { rmtree $dirname; kill INT => $$ };

my $source1_filename = catfile($dirname, 'source1');
$graph->add_file($source1_filename, action => 'spew', arguments => { content => 'Hello' }, dependencies => [ $dirname ]);

my $source2_filename = catfile($dirname, 'source2');
$graph->add_file($source2_filename, action => 'spew', arguments => { content => 'World' }, dependencies => [ $dirname, $source1_filename ]);

$graph->add_phony('build', action => 'noop', dependencies => [ $source1_filename, $source2_filename ]);
$graph->add_phony('test', action => 'noop', dependencies => [ 'build' ]);
$graph->add_phony('install', action => 'noop', dependencies => [ 'build' ]);

my @sorted = $graph->_sort_nodes('build');

is_deeply \@sorted, [ $dirname, $source1_filename, $source2_filename, 'build' ], 'topological sort is ok';

my @runs     = qw/build test install/;
my %expected = (
	build => [
		[qw{_testing _testing/source1 _testing/source2 build}],
		[qw/build/],

		sub { rmtree $dirname },
		[qw{_testing _testing/source1 _testing/source2 build}],
		[qw/build/],

		sub { unlink $source2_filename or die "Couldn't remove $source2_filename: $!" },
		[qw{_testing/source2 build}],
		[qw/build/],

		sub { unlink $source1_filename },
		[qw{_testing/source1 _testing/source2 build}],
		[qw/build/],
	],
	test    => [ [qw{_testing _testing/source1 _testing/source2 build test}],    [qw/build test/] ],
	install => [ [qw{_testing _testing/source1 _testing/source2 build install}], [qw/build install/] ],
);

my ($run, @expected);
sub next_is {
	my $gotten   = shift;
	my $index    = first_index { $_ eq $gotten } @expected;
	my $expected = $expected[0];
	splice @expected, $index, 1 if $index > -1;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is $gotten, $expected, sprintf "Expecting %s", (defined $expected ? "'$expected'" : 'undef');
}

my $simple = $graph->nodes_to_hashref;
my $clone = Build::Graph->new;
$clone->load_from_hashref($simple);
add_actions($clone);

for my $current ($graph, $clone) {
	for my $runner (sort keys %expected) {
		rmtree $dirname;
		$run = $runner;
		for my $runpart (@{ $expected{$runner} }) {
			if (ref($runpart) eq 'CODE') {
				$runpart->();
			}
			else {
				@expected = @{$runpart};
				$current->run($run, verbosity => 1);
				eq_or_diff \@expected, [], "\@expected is empty at the end of run $run";
				diag(sprintf "Still expecting %s", join ', ', map { "'$_'" } @expected) if @expected;
				sleep 1;
			}
		}
	}
}

done_testing();

sub spew {
	my ($filename, $content) = @_;
	open my $fh, '>', $filename or croak "Couldn't open file '$filename' for writing: $!\n";
	print $fh $content;
	close $fh or croak "couldn't close $filename: $!\n";
	return;
}

