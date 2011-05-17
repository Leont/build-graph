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

my $command_set = Build::Graph::CommandSet->new;
$command_set->add('spew' => sub { my ($name, $arguments) = @_; next_is($name); spew($name, $arguments) });
$command_set->add('poke' => sub { next_is('poke') });
$command_set->add('noop' => sub { next_is($_[0]) });
my $graph = Build::Graph->new(commands => $command_set);

my $dirname = '_testing';
END { rmtree $dirname }
$SIG{INT} = sub { rmtree $dirname; kill INT => $$ };

my $source1_filename = catfile($dirname, 'source1');
$graph->add_file($source1_filename, actions => [ 'poke', { command => 'spew', arguments => 'Hello' } ]);

my $source2_filename = catfile($dirname, 'source2');
$graph->add_file($source2_filename, actions => { command => 'spew', arguments => 'World' }, dependencies => [ $source1_filename ]);

$graph->add_phony('build', actions => 'noop', dependencies => [ $source1_filename, $source2_filename ]);
$graph->add_phony('test', actions => 'noop', dependencies => [ 'build' ]);
$graph->add_phony('install', actions => 'noop', dependencies => [ 'build' ]);

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

		sub { unlink $source1_filename },
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
my $clone = Build::Graph->new(commands => $command_set);
$clone->load_from_hashref($simple);

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

