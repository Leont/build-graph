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

use Graph::Dependency::OP;
use Graph::Dependency::OP::Node::File;
use Graph::Dependency::OP::Node::Phony;

my $dirname = '_testing';

END { rmtree $dirname };

my $dir = Graph::Dependency::OP::Node::File->new(name => 'dir', filename => $dirname, action => sub { next_is('mkdir'); mkdir $dirname or die "Couldn't mkdir $dirname: $!"}, message => "mkdir $dirname");

my $source1_filename = catfile($dirname, 'source1');
my $source1 = Graph::Dependency::OP::Node::File->new(name => 'source1', filename => $source1_filename, action => sub { next_is('source1'); spew($source1_filename, 'Hello ') }, message => 'Creating source1', dependencies => [ $dir ]);

my $source2_filename = catfile($dirname, 'source2');
my $source2 = Graph::Dependency::OP::Node::File->new(name => 'source1', filename => $source2_filename, action => sub { next_is('source2'); spew($source2_filename, 'World!'); }, message => 'Creating source2', dependencies => [ $dir, $source1 ]);

my $build = Graph::Dependency::OP::Node::Phony->new(name => 'build', action => sub { next_is('build_complete') }, message => 'building distribution', dependencies => [ $source2, $source1 ]);
my $test = Graph::Dependency::OP::Node::Phony->new(name => 'test', action => sub { next_is('testing') }, message => 'testing distribution', dependencies => [ $build ]);
my $install = Graph::Dependency::OP::Node::Phony->new(name => 'install', action => sub { next_is('installing') }, message => 'installing distribution', dependencies => [ $build ]);

ok scalar($_->dependencies), $_->message . " has depenencies" for ($source2, $build, $test, $install);

my $graph = Graph::Dependency::OP->new(nodes => { build => $build, test => $test, install => $install }, verbosity => 0);

my @runs = qw/build test install/;
my %expected = (
	build => [ 
		[qw/mkdir source1 source2 build_complete/],
		[qw/build_complete/],

		sub { rmtree $dirname },
		[qw/mkdir source1 source2 build_complete/],
		[qw/build_complete/],

		sub { unlink $source2_filename or die "Couldn't remove $source2_filename: $!" },
		[qw/source2 build_complete/],
		[qw/build_complete/],

		sub { unlink $source1_filename },
		[qw/source1 source2 build_complete/],
		[qw/build_complete/],
	],
	test => [ [qw/mkdir source1 source2 build_complete testing/], [qw/build_complete testing/] ],
	install => [ [qw/mkdir source1 source2 build_complete installing/], [qw/build_complete installing/] ],
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

rmtree $dirname;
for my $runner (sort keys %expected) {
	$run = $runner;
	for my $runpart (@{ $expected{$runner} }) {
		if (ref($runpart) eq 'CODE') {
			$runpart->();
		}
		else {
			@expected = @{$runpart};
			$graph->run($run, verbosity => 1);
			eq_or_diff \@expected, [], "\@expected is empty at the end of run $run";
			diag(sprintf "Still expecting %s", join ', ', map { "'$_'" } @expected) if @expected;
			sleep 1;
		}
	}
	rmtree $dirname;
}

done_testing();

sub spew {
	my ($filename, $content) = @_;
	open my $fh, '>', $filename or croak "Couldn't open file '$filename' for writing: $!\n";
	print $fh $content;
	close $fh or croak "couldn't close $filename: $!\n";
	return;
}

