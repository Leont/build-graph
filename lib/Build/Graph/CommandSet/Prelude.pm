package Build::Graph::CommandSet::Prelude;

use strict;
use warnings;

use base 'Build::Graph::Role::CommandSet';

use Build::Graph::Callable::Macro;

use Carp qw/croak/;

my $quote = $^O eq 'MSWin32' ? do { require Win32::ShellQuote; \&Win32::ShellQuote::quote_system_list } : sub { @_ };

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	my %commands = (
		exec => sub {
			my @args = @_;
			my @quoted = $quote->(@args);
			system @quoted and die "@args returned $?";
			return;
		},
		load => sub {
			my @modules = @_;
			for my $module (@modules) {
				(my $file = "$module.pm") =~ s{::}{/}g;
				require $file;
			}
			return;
		},
		call => sub {
			my ($function, @arguments) = @_;
			my $sub = do { no strict 'refs'; \&{ $function } } || die "No such function $function";
			return $sub->(@arguments);
		},
		'copy' => sub {
			my ($args, $source, $target) = @_;

			require File::Copy;
			File::Copy::copy($source, $target) or croak "Could not copy: $!";
			printf "cp %s %s\n", $source, $target;

			my ($atime, $mtime) = (stat $source)[8,9];
			utime $atime, $mtime, $target;
			chmod 0444 & ~umask, $target;

			return;
		},
		'rm-r' => sub {
			my ($args, @files) = @_;
			require File::Path;
			File::Path::rmtree(\@files, $args->{verbose}, 0);
			return;
		},
		'mkdir' => sub {
			my ($args, $target) = @_;
			File::Path::mkpath($target, $args->{verbose});
			return;
		},
		'touch' => sub {
			my ($args, $target) = @_;

			open my $fh, '>', $target or croak "Could not create $target: $!";
			close $fh or croak "Could not create $target: $!";
		},
		true => sub {
			return 1;
		},
		false => sub {
			return 0;
		},
	);

	for my $key (keys %commands) {
		$self->{graph}->add_action($key, $commands{$key});
	}

	my %macros = (
		if => sub {
			my ($graph, $opt, $condition, $true, $false) = @_;
			return 0 if not ref($condition) eq 'ARRAY';
			my $value = $graph->eval_action($opt, @{ $condition });
			if ($value) {
				$graph->eval_action($opt, @{ $true });
			}
			elsif ($false) {
				$graph->eval_action($opt, @{ $false });
			}
		},
	);

	for my $key (keys %macros) {
		my $macro = Build::Graph::Callable::Macro->new(
			graph => $self->{graph},
			callback => $macros{$key},
		);
		$self->{graph}->add_action($key, $macro);
	}

	return $self;
}

1;

# ABSTRACT: A set of general purpose functions
