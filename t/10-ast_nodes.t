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

use Graph::Dependency;

my $ast = Graph::Dependency->new;

my $dirname = '_testing';
$ast->add_file($dirname, action => 'mkdir');
END { rmtree $dirname };

my $source1_filename = catfile($dirname, 'source1');
$ast->add_file($source1_filename, action => 'cat', arguments => { content => 'Hello' }, dependencies => { $dirname => 'dir' });

my $source2_filename = catfile($dirname, 'source2');
$ast->add_file($source2_filename, action => 'cat', arguments => { content => 'Would' }, dependencies => { $dirname => 'dir', $source1_filename => 'other' });

$ast->add_phony('build', action => 'noop', dependencies => { $source1_filename => 'file', $source2_filename => 'file' });
$ast->add_phony('test', action => 'noop', dependencies => { build => 'build' });
$ast->add_phony('install', action => 'noop', dependencies => { build => 'build' });

my @sorted = $ast->_sort_nodes('build');

is_deeply \@sorted, [ $dirname, $source1_filename, $source2_filename, 'build' ], 'topological sort is ok';

$ast->add_action('mkdir' => sub { next_is($_[0]); mkdir $_[0] });
$ast->add_action('cat' => sub { my ($name, $node) = @_; next_is($name); spew($name, $node->get_argument('content')) });
$ast->add_action('noop' => sub { next_is($_[0]) });

my @runs = qw/build test install/;
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
	test => [ [qw{_testing _testing/source1 _testing/source2 build test}], [qw/build test/] ],
	install => [ [qw{_testing _testing/source1 _testing/source2 build install}], [qw/build install/] ],
);

my ($run, @expected);
sub next_is {
	my $gotten = shift;
	my $index = first_index { $_ eq $gotten } @expected;
	my $expected = $expected[0];
	splice @expected, $index, 1 if $index > -1;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	is $gotten, $expected, sprintf "Expecting %s", (defined $expected ? "'$expected'" : 'undef');
}

for my $runner (sort keys %expected) {
	rmtree $dirname;
	$run = $runner;
	for my $runpart (@{ $expected{$runner} }) {
		if (ref($runpart) eq 'CODE') {
			$runpart->();
		}
		else {
			@expected = @{$runpart};
			$ast->run($run, verbosity => 1);
			eq_or_diff \@expected, [], "\@expected is empty at the end of run $run";
			diag(sprintf "Still expecting %s", join ', ', map { "'$_'" } @expected) if @expected;
			sleep 1;
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

