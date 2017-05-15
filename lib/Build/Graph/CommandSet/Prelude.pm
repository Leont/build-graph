package Build::Graph::CommandSet::Prelude;

use strict;
use warnings;

use base 'Build::Graph::Role::CommandSet';

use Build::Graph::Callable::Macro;

use Carp qw/croak/;

sub new {
	my ($class, %args) = @_;
	my $self = $class->SUPER::new(%args);
	my %commands = (
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
	);

	for my $key (keys %commands) {
		$self->{graph}->add_action($key, $commands{$key});
	}

	return $self;
}

1;

# ABSTRACT: A set of general purpose functions
